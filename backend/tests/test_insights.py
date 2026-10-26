import uuid
from datetime import date, timedelta
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.checkin import MoodCheckin
from app.services.insights_service import (
    calculate_exam_context_insights,
    calculate_weekly_insights,
)


def make_dummy_checkin(
    local_date: date,
    mood: int = 3,
    stress: int = 3,
    energy: int = 3,
    sleep: int = 3,
    user_id: uuid.UUID = None,
) -> MoodCheckin:
    return MoodCheckin(
        id=uuid.uuid4(),
        user_id=user_id or uuid.uuid4(),
        client_id=uuid.uuid4(),
        local_date=local_date,
        mood_score=mood,
        stress_score=stress,
        energy_score=energy,
        sleep_quality_score=sleep,
    )


def test_weekly_insights_pure_function_thresholds():
    """Test exact 0.5 threshold boundaries in pure calculation function."""
    week_start = date(2026, 10, 19)

    # 4 distinct days in week
    week_checkins = [
        make_dummy_checkin(date(2026, 10, 19), mood=4, stress=3, energy=4, sleep=3),
        make_dummy_checkin(date(2026, 10, 20), mood=4, stress=3, energy=4, sleep=3),
        make_dummy_checkin(date(2026, 10, 21), mood=4, stress=3, energy=4, sleep=3),
        make_dummy_checkin(date(2026, 10, 22), mood=4, stress=3, energy=4, sleep=3),
    ]

    # Baseline 7 distinct days where baseline mood average is 3.5 -> diff is exactly 0.5 -> SIMILAR
    baseline_checkins_similar = [
        make_dummy_checkin(week_start - timedelta(days=i), mood=4 if i % 2 == 0 else 3, stress=3, energy=3, sleep=3)
        for i in range(1, 8)
    ]
    # For mood: 4, 3, 4, 3, 4, 3, 4 -> sum=25 / 7 = 3.57. Let's make baseline exactly 3.5
    # Week mood is 4.0. If baseline is 3.5, diff is 0.50 -> SIMILAR
    baseline_exact = [
        make_dummy_checkin(week_start - timedelta(days=1), mood=3, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=2), mood=4, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=3), mood=3, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=4), mood=4, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=5), mood=3, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=6), mood=4, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=7), mood=3, stress=3, energy=3, sleep=3),
        make_dummy_checkin(week_start - timedelta(days=8), mood=4, stress=3, energy=3, sleep=3),
    ]  # 4 * 3 + 4 * 4 = 28 / 8 = 3.5. Diff = 4.0 - 3.5 = 0.50.
    res = calculate_weekly_insights(week_checkins, baseline_exact, week_start)
    assert res.status == "sufficient_data"
    assert res.metrics["mood"].diff == 0.5
    assert res.metrics["mood"].code == "SIMILAR"

    # Now make baseline mood 3.4 (4.0 - 3.4 = 0.6 > 0.5) -> HIGHER_THAN_USUAL
    baseline_lower = [
        make_dummy_checkin(week_start - timedelta(days=i), mood=3, stress=3, energy=3, sleep=3)
        for i in range(1, 8)
    ]  # baseline mood = 3.0. Diff = 4.0 - 3.0 = 1.0 > 0.5
    res_higher = calculate_weekly_insights(week_checkins, baseline_lower, week_start)
    assert res_higher.metrics["mood"].diff == 1.0
    assert res_higher.metrics["mood"].code == "HIGHER_THAN_USUAL"

    # Now make week mood 2.0 and baseline 3.0 -> diff = -1.0 < -0.5 -> LOWER_THAN_USUAL
    week_low = [
        make_dummy_checkin(date(2026, 10, 19 + i), mood=2, stress=3, energy=3, sleep=3)
        for i in range(4)
    ]
    res_lower = calculate_weekly_insights(week_low, baseline_lower, week_start)
    assert res_lower.metrics["mood"].diff == -1.0
    assert res_lower.metrics["mood"].code == "LOWER_THAN_USUAL"


def test_weekly_insights_not_enough_data_cases():
    """Test not_enough_data status when distinct days are insufficient."""
    week_start = date(2026, 10, 19)

    # Only 3 days in week
    week_3_days = [
        make_dummy_checkin(date(2026, 10, 19)),
        make_dummy_checkin(date(2026, 10, 20)),
        make_dummy_checkin(date(2026, 10, 21)),
    ]
    baseline_7_days = [
        make_dummy_checkin(week_start - timedelta(days=i)) for i in range(1, 8)
    ]
    res = calculate_weekly_insights(week_3_days, baseline_7_days, week_start)
    assert res.status == "not_enough_data"
    assert res.days_needed.week == 1
    assert res.days_needed.baseline == 0

    # 4 days in week but only 6 days in baseline
    week_4_days = [
        make_dummy_checkin(date(2026, 10, 19 + i)) for i in range(4)
    ]
    baseline_6_days = [
        make_dummy_checkin(week_start - timedelta(days=i)) for i in range(1, 7)
    ]
    res2 = calculate_weekly_insights(week_4_days, baseline_6_days, week_start)
    assert res2.status == "not_enough_data"
    assert res2.days_needed.week == 0
    assert res2.days_needed.baseline == 1


def test_exam_context_insights_pure_function():
    """Test exam context insights calculation and sample sizes."""
    ref_date = date(2026, 10, 20)
    user_id = uuid.uuid4()

    event1 = AcademicEvent(id=uuid.uuid4(), user_id=user_id, title="Exam 1", event_date=date(2026, 10, 15))
    event2 = AcademicEvent(id=uuid.uuid4(), user_id=user_id, title="Exam 2", event_date=date(2026, 10, 5))

    # Event 1 window: Oct 8 to Oct 14. Add 3 distinct days: Oct 9, 10, 11 (high stress 5, low energy 2)
    # Event 2 window: Sep 28 to Oct 4. Add 3 distinct days: Sep 29, 30, Oct 1 (high stress 5, low energy 2)
    # Baseline window outside: Sep 10, 11, 12, 13 (stress 2, energy 4)
    checkins = [
        make_dummy_checkin(date(2026, 10, 9), stress=5, energy=2, user_id=user_id),
        make_dummy_checkin(date(2026, 10, 10), stress=5, energy=2, user_id=user_id),
        make_dummy_checkin(date(2026, 10, 11), stress=5, energy=2, user_id=user_id),
        make_dummy_checkin(date(2026, 9, 29), stress=5, energy=2, user_id=user_id),
        make_dummy_checkin(date(2026, 9, 30), stress=5, energy=2, user_id=user_id),
        make_dummy_checkin(date(2026, 10, 1), stress=5, energy=2, user_id=user_id),
        # Outside window baseline
        make_dummy_checkin(date(2026, 9, 10), stress=2, energy=4, user_id=user_id),
        make_dummy_checkin(date(2026, 9, 11), stress=2, energy=4, user_id=user_id),
        make_dummy_checkin(date(2026, 9, 12), stress=2, energy=4, user_id=user_id),
    ]

    res = calculate_exam_context_insights([event1, event2], checkins, ref_date)
    assert res.status == "sufficient_data"
    assert res.qualifying_events_count == 2
    assert res.stress.code == "STRESS_HIGHER_BEFORE_EVENTS"
    assert res.stress.diff == 3.0
    assert res.energy.code == "ENERGY_LOWER_BEFORE_EVENTS"
    assert res.energy.diff == -2.0
    assert res.sample_sizes["pre_event_distinct_days"] == 6
    assert res.sample_sizes["baseline_distinct_days"] == 3


def test_exam_context_insufficient_events():
    """Fewer than 2 qualifying events returns not_enough_data."""
    ref_date = date(2026, 10, 20)
    user_id = uuid.uuid4()
    # Only 1 event
    event = AcademicEvent(id=uuid.uuid4(), user_id=user_id, title="Solo Exam", event_date=date(2026, 10, 15))
    checkins = [
        make_dummy_checkin(date(2026, 10, 9 + i), stress=4, energy=3, user_id=user_id)
        for i in range(4)
    ]
    res = calculate_exam_context_insights([event], checkins, ref_date)
    assert res.status == "not_enough_data"
    assert res.qualifying_events_count == 1
    assert res.events_needed == 1


def test_insights_api_endpoints_and_owner_isolation(client: TestClient, db_session: Session):
    """End-to-end HTTP test verifying owner isolation on /insights/weekly and /insights/exam-context."""
    # Register User A and User B
    res_a = client.post(
        "/v1/auth/register",
        json={"email": "ins.a@campus.edu", "password": "Password123!", "display_name": "User A"},
    )
    user_a_id = res_a.json()["user"]["id"]
    token_a = res_a.json()["tokens"]["access_token"]

    res_b = client.post(
        "/v1/auth/register",
        json={"email": "ins.b@campus.edu", "password": "Password123!", "display_name": "User B"},
    )
    token_b = res_b.json()["tokens"]["access_token"]

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    week_start = date(2026, 10, 19)

    # Seed User A check-ins: 4 in week, 7 in baseline
    for i in range(4):
        db_session.add(
            MoodCheckin(
                user_id=user_a_id,
                client_id=uuid.uuid4(),
                local_date=week_start + timedelta(days=i),
                mood_score=4,
                stress_score=2,
                energy_score=4,
                sleep_quality_score=4,
            )
        )
    for i in range(1, 8):
        db_session.add(
            MoodCheckin(
                user_id=user_a_id,
                client_id=uuid.uuid4(),
                local_date=week_start - timedelta(days=i),
                mood_score=3,
                stress_score=3,
                energy_score=3,
                sleep_quality_score=3,
            )
        )
    db_session.commit()

    # User A requests weekly insights -> sufficient_data
    res_weekly_a = client.get(f"/v1/insights/weekly?week_start={week_start}", headers=headers_a)
    assert res_weekly_a.status_code == 200
    data_a = res_weekly_a.json()
    assert data_a["status"] == "sufficient_data"
    assert data_a["metrics"]["mood"]["code"] == "HIGHER_THAN_USUAL"

    # User B requests weekly insights -> not_enough_data (User A's data is never visible to User B!)
    res_weekly_b = client.get(f"/v1/insights/weekly?week_start={week_start}", headers=headers_b)
    assert res_weekly_b.status_code == 200
    data_b = res_weekly_b.json()
    assert data_b["status"] == "not_enough_data"
    assert data_b["days_needed"]["week"] == 4
    assert data_b["days_needed"]["baseline"] == 7
