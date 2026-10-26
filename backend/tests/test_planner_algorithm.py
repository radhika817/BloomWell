import math
import uuid
from datetime import date, timedelta
import pytest

from app.services.planner_algorithm import (
    ALLOWED_REASON_CODES,
    AcademicEventInput,
    ActivityCandidate,
    CycleRecordInput,
    generate_study_plan_schedule,
)


def test_planner_algorithm_13_vs_14_days_boundary():
    """Test exact boundary: 13 days history is default mode; 14 days is personalized mode."""
    week_start = date(2026, 11, 2)

    # 13 days history
    history_13 = {
        week_start - timedelta(days=i): 4.0 for i in range(1, 14)
    }
    plan_13 = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history_13,
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    assert plan_13.mode == "default"
    assert plan_13.checkin_days_used == 13
    assert all(item.suggested_load == "normal" for item in plan_13.items)
    assert all("NOT_ENOUGH_HISTORY" in item.reason_codes for item in plan_13.items)

    # 14 days history
    history_14 = {
        week_start - timedelta(days=i): 4.0 for i in range(1, 15)
    }
    plan_14 = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history_14,
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    assert plan_14.mode == "personalized"
    assert plan_14.checkin_days_used == 14


def test_planner_algorithm_low_sd_all_normal():
    """If standard deviation of daily energy is below 0.5, every day is normal."""
    week_start = date(2026, 11, 2)
    # Energy scores with SD < 0.5 (e.g. alternating 3.0 and 3.2)
    history = {}
    for i in range(1, 15):
        history[week_start - timedelta(days=i)] = 3.0 if i % 2 == 0 else 3.2

    plan = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history,
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    assert plan.mode == "personalized"
    assert all(item.suggested_load == "normal" for item in plan.items)
    assert all("DEFAULT_PLAN" in item.reason_codes for item in plan.items)


def test_planner_algorithm_weekday_classification_and_single_sample():
    """
    Test weekday classification when SD >= 0.5:
    - > 0.5 SD above mean -> focus (WEEKDAY_ENERGY_HIGHER)
    - > 0.5 SD below mean -> light (WEEKDAY_ENERGY_LOWER)
    - Weekdays with only 1 sample -> normal (DEFAULT_PLAN)
    """
    week_start = date(2026, 11, 2)  # Monday

    # Build 14-day history where:
    # Mondays (Nov 2, etc.): 2 samples with very high energy (5.0)
    # Tuesdays: 2 samples with very low energy (1.0)
    # Wednesdays: only 1 sample (3.0) -> should be normal
    # Other days: balanced around mean 3.0
    history = {
        week_start - timedelta(days=7): 5.0,   # Prior Mon
        week_start - timedelta(days=14): 5.0,  # 2nd prior Mon
        week_start - timedelta(days=6): 1.0,   # Prior Tue
        week_start - timedelta(days=13): 1.0,  # 2nd prior Tue
        week_start - timedelta(days=5): 3.0,   # Prior Wed (1 sample)
        week_start - timedelta(days=4): 3.0,   # Thu 1
        week_start - timedelta(days=11): 3.0,  # Thu 2
        week_start - timedelta(days=3): 3.0,   # Fri 1
        week_start - timedelta(days=10): 3.0,  # Fri 2
        week_start - timedelta(days=2): 3.0,   # Sat 1
        week_start - timedelta(days=9): 3.0,   # Sat 2
        week_start - timedelta(days=1): 3.0,   # Sun 1
        week_start - timedelta(days=8): 3.0,   # Sun 2
        week_start - timedelta(days=15): 3.0,  # 14th day
    }

    plan = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history,
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    assert plan.mode == "personalized"
    # Monday is high energy -> focus
    mon_item = plan.items[0]
    assert mon_item.suggested_load == "focus"
    assert "WEEKDAY_ENERGY_HIGHER" in mon_item.reason_codes

    # Tuesday is low energy -> light
    tue_item = plan.items[1]
    assert tue_item.suggested_load == "light"
    assert "WEEKDAY_ENERGY_LOWER" in tue_item.reason_codes

    # Wednesday has only 1 sample -> normal
    wed_item = plan.items[2]
    assert wed_item.suggested_load == "normal"
    assert "DEFAULT_PLAN" in wed_item.reason_codes


def test_planner_algorithm_cycle_adjustment_rules():
    """
    Test cycle adjustment constraints:
    - Never applied if consent is False or tracking is False
    - Requires >= 3 cycles and >= 6 period-day check-ins
    - Requires energy drop >= 0.7 on period days
    - Moves one step toward light (focus -> normal, normal -> light)
    - Sets uses_cycle_data = True
    """
    week_start = date(2026, 11, 2)  # Monday
    history = {}
    for i in range(1, 21):
        # Base energy 4.0
        history[week_start - timedelta(days=i)] = 4.0

    # 3 recorded cycles with period days having energy 2.5 (drop = 4.0 - 2.5 = 1.5 >= 0.7)
    # Cycle 1: Oct 1 - Oct 5 (5 days)
    # Cycle 2: Oct 10 - Oct 14 (5 days)
    # Cycle 3: Nov 1 - Nov 4 (current period overlapping week_start!)
    cycles = [
        CycleRecordInput(period_start=date(2026, 10, 1), period_end=date(2026, 10, 5)),
        CycleRecordInput(period_start=date(2026, 10, 10), period_end=date(2026, 10, 14)),
        CycleRecordInput(period_start=date(2026, 11, 1), period_end=date(2026, 11, 4)),
    ]
    # Set check-in scores for period days in history to 2.5 (more than 6 samples)
    for d in [date(2026, 10, 1), date(2026, 10, 2), date(2026, 10, 3), date(2026, 10, 10), date(2026, 10, 11), date(2026, 10, 12), date(2026, 11, 1)]:
        history[d] = 2.5

    # 1. Without consent: uses_cycle_data is False, NO cycle adjustment
    plan_no_consent = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history,
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=True,
        recorded_cycles=cycles,
        break_activities=[],
    )
    assert plan_no_consent.uses_cycle_data is False
    assert all("CYCLE_RECORDED_PERIOD_LOW_ENERGY" not in item.reason_codes for item in plan_no_consent.items)

    # 2. With consent and tracking enabled:
    plan_consented = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history,
        academic_events=[],
        cycle_consent=True,
        cycle_tracking_enabled=True,
        recorded_cycles=cycles,
        break_activities=[],
    )
    assert plan_consented.uses_cycle_data is True
    # Nov 2, 3, 4 are inside Cycle 3 recorded period!
    # They were normal, now should be light with CYCLE_RECORDED_PERIOD_LOW_ENERGY
    nov2 = plan_consented.items[0]
    assert nov2.suggested_load == "light"
    assert "CYCLE_RECORDED_PERIOD_LOW_ENERGY" in nov2.reason_codes


def test_planner_algorithm_exam_rules_and_preservation():
    """
    Test exam rules:
    - 2nd to 5th day before event is focus in default mode (EVENT_PREP)
    - Event day itself is never light (EVENT_DAY)
    - No 3-day stretch before event may be all light (KEEP_OPTION_PRESERVED)
    """
    week_start = date(2026, 11, 2)  # Monday
    # Exam on Saturday Nov 7
    exam_event = AcademicEventInput(
        id=uuid.uuid4(),
        event_date=date(2026, 11, 7),
        title="Calculus Exam",
    )

    # Default mode: 2nd to 5th day before Nov 7:
    # Nov 2 (Mon, 5 days before), Nov 3 (Tue, 4 days before), Nov 4 (Wed, 3 days before), Nov 5 (Thu, 2 days before) -> all focus!
    plan_default = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history={},  # 0 days -> default mode
        academic_events=[exam_event],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    assert plan_default.items[0].suggested_load == "focus"  # Nov 2
    assert "EVENT_PREP" in plan_default.items[0].reason_codes
    assert plan_default.items[5].suggested_load == "normal"  # Nov 7 (event day)
    assert "EVENT_DAY" in plan_default.items[5].reason_codes

    # Test 3-day stretch all-light rule:
    # Suppose days Nov 2, 3, 4 were classified as light before exam on Nov 6
    # One of them must be raised to normal with KEEP_OPTION_PRESERVED
    exam_fri = AcademicEventInput(id=uuid.uuid4(), event_date=date(2026, 11, 6), title="Exam")
    # Personalized history where weekdays are low energy
    history = {}
    for i in range(1, 15):
        history[week_start - timedelta(days=i)] = 1.0 if (week_start - timedelta(days=i)).weekday() in [0, 1, 2] else 5.0

    plan_exam = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history=history,
        academic_events=[exam_fri],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[],
    )
    # Check that in the 3 days (Nov 2, 3, 4), they are not all light!
    loads = [plan_exam.items[0].suggested_load, plan_exam.items[1].suggested_load, plan_exam.items[2].suggested_load]
    assert not all(l == "light" for l in loads)
    reasons = [r for item in plan_exam.items[:3] for r in item.reason_codes]
    assert "KEEP_OPTION_PRESERVED" in reasons


def test_planner_algorithm_break_activities_and_determinism():
    """
    Test break activity selection:
    - Deterministic order
    - Prefers favorites
    - Never consecutive duplicate
    - If none, None
    - Determinism: exact same outputs on repeated calls
    """
    week_start = date(2026, 11, 2)
    fav_act = ActivityCandidate(id=uuid.uuid4(), is_favorite=True, is_published=True)
    normal_act = ActivityCandidate(id=uuid.uuid4(), is_favorite=False, is_published=True)

    plan1 = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history={},
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[normal_act, fav_act],
    )
    plan2 = generate_study_plan_schedule(
        week_start=week_start,
        daily_energy_history={},
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[normal_act, fav_act],
    )

    # Determinism
    for i in range(7):
        assert plan1.items[i].plan_date == plan2.items[i].plan_date
        assert plan1.items[i].suggested_load == plan2.items[i].suggested_load
        assert plan1.items[i].reason_codes == plan2.items[i].reason_codes
        assert plan1.items[i].activity_id == plan2.items[i].activity_id

    # Rotation: Day 0 is favorite, Day 1 is normal, Day 2 is favorite...
    assert plan1.items[0].activity_id == fav_act.id
    assert plan1.items[1].activity_id == normal_act.id
    assert plan1.items[2].activity_id == fav_act.id
    assert plan1.items[0].activity_id != plan1.items[1].activity_id

    # Verify all reason codes belong to ALLOWED_REASON_CODES
    for item in plan1.items:
        for r in item.reason_codes:
            assert r in ALLOWED_REASON_CODES
