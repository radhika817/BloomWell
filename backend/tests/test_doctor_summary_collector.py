"""Tests for Doctor-visit summary data collector and two-account isolation."""

import uuid
from datetime import date, timedelta
import pytest
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.user import User
from app.repositories.cycle_repository import CycleRepository
from app.repositories.symptom_repository import SymptomRepository
from app.schemas.doctor_summary import DoctorSummaryInclude, DoctorSummaryRequest
from app.services.cycle_algorithm import calculate_cycle_estimate
from app.services.doctor_summary_service import (
    DoctorSummaryCollectorService,
    SummaryTooLargeError,
)


def _create_user(db: Session, email_prefix: str = "collector_test") -> User:
    user = User(
        email=f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="test_secret_hashed",
        display_name="Collector Subject",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def test_pure_cycle_estimate_algorithm():
    """Verify cycle estimate logic handles insufficient data, gaps, variability, and regular cycles."""
    # 1. Less than 2 starts -> not enough data
    res1 = calculate_cycle_estimate([date(2026, 1, 1)])
    assert res1.status == "not_enough_data"

    # 2. Less than 3 usable lengths -> not enough data
    res2 = calculate_cycle_estimate([
        date(2026, 1, 1),
        date(2026, 1, 29),
        date(2026, 2, 26),
    ])
    assert res2.status == "not_enough_data"
    assert res2.needed_cycles == 1

    # 3. Gap > 90 days dropped
    res3 = calculate_cycle_estimate([
        date(2025, 1, 1),
        date(2025, 1, 29),  # 28 days
        date(2025, 6, 1),   # gap > 90 days dropped
        date(2025, 6, 29),  # 28 days
    ])
    # only 2 usable lengths (28, 28)
    assert res3.status == "not_enough_data"

    # 4. Too variable (> 15 days spread in recent cycles)
    res4 = calculate_cycle_estimate([
        date(2026, 1, 1),
        date(2026, 1, 22),  # 21 days
        date(2026, 2, 19),  # 28 days
        date(2026, 3, 31),  # 40 days (spread = 40 - 21 = 19 > 15)
    ])
    assert res4.status == "too_variable"
    assert "vary too much" in res4.explanation

    # 5. Normal regular cycles -> valid estimate with range
    res5 = calculate_cycle_estimate([
        date(2026, 1, 1),
        date(2026, 1, 29),  # 28 days
        date(2026, 2, 26),  # 28 days
        date(2026, 3, 26),  # 28 days
    ])
    assert res5.status == "estimate"
    assert res5.typical_cycle_length_days == 28
    assert res5.estimated_range_start is not None
    assert res5.estimated_range_end is not None
    # Range is around March 26 + 28 = April 23 +/- margin
    assert res5.estimated_range_start <= date(2026, 4, 23) <= res5.estimated_range_end


def test_doctor_summary_collector_periods_and_cycle_lengths(db_session: Session):
    """Verify overlapping periods are retrieved with cycle lengths computed from prior start."""
    user = _create_user(db_session)
    cycle_repo = CycleRepository(db_session)

    # User logged 3 periods:
    # Period 1: Jan 1 - Jan 5 (cycle length None)
    # Period 2: Jan 29 - Feb 3 (cycle length 28)
    # Period 3: Feb 26 - Mar 2 (cycle length 28)
    p1 = cycle_repo.create_cycle_log(user.id, date(2026, 1, 1), date(2026, 1, 5))
    p2 = cycle_repo.create_cycle_log(user.id, date(2026, 1, 29), date(2026, 2, 3))
    p3 = cycle_repo.create_cycle_log(user.id, date(2026, 2, 26), date(2026, 3, 2))

    collector = DoctorSummaryCollectorService(db_session)

    # Request range covering Jan 20 to Feb 10 (overlaps Period 2 only)
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 20),
        to_date=date(2026, 2, 10),
        include=DoctorSummaryInclude(periods=True, symptoms=False),
    )

    data = collector.collect_summary_data(user.id, req)
    assert len(data.periods) == 1
    assert data.periods[0].period_start == date(2026, 1, 29)
    assert data.periods[0].period_end == date(2026, 2, 3)
    # Cycle length relative to Jan 1 is 28 days
    assert data.periods[0].cycle_length_days == 28
    assert "Recorded periods" in data.included_categories
    assert "Logged symptoms" not in data.included_categories


def test_doctor_summary_collector_symptoms_grouping_and_notes(db_session: Session):
    """Verify symptoms are grouped by type/label, severities aggregated, and notes respect toggle."""
    user = _create_user(db_session)
    symptom_repo = SymptomRepository(db_session)

    symptom_repo.create_symptom_log(
        user.id, date(2026, 2, 1), "cramps", 3, notes="Mild morning cramps"
    )
    symptom_repo.create_symptom_log(
        user.id, date(2026, 2, 2), "cramps", 5, notes="Severe evening cramps"
    )
    symptom_repo.create_symptom_log(
        user.id, date(2026, 2, 2), "headache", 2, custom_label="Migraine", notes="Left side"
    )

    collector = DoctorSummaryCollectorService(db_session)

    # 1. Without symptom notes
    req_no_notes = DoctorSummaryRequest(
        from_date=date(2026, 2, 1),
        to_date=date(2026, 2, 5),
        include=DoctorSummaryInclude(periods=False, symptoms=True, symptom_notes=False),
    )
    data_no_notes = collector.collect_summary_data(user.id, req_no_notes)
    assert len(data_no_notes.symptoms) == 2

    cramps_group = next(s for s in data_no_notes.symptoms if s.symptom_type == "cramps")
    assert cramps_group.days_logged == 2
    assert cramps_group.min_severity == 3
    assert cramps_group.max_severity == 5
    assert cramps_group.dates == [date(2026, 2, 1), date(2026, 2, 2)]
    assert cramps_group.notes == []  # Notes excluded

    # 2. With symptom notes
    req_with_notes = DoctorSummaryRequest(
        from_date=date(2026, 2, 1),
        to_date=date(2026, 2, 5),
        include=DoctorSummaryInclude(periods=False, symptoms=True, symptom_notes=True),
    )
    data_with_notes = collector.collect_summary_data(user.id, req_with_notes)
    cramps_with_notes = next(s for s in data_with_notes.symptoms if s.symptom_type == "cramps")
    assert cramps_with_notes.notes == ["Mild morning cramps", "Severe evening cramps"]
    assert "Symptom notes" in data_with_notes.included_categories


def test_doctor_summary_collector_estimate_inclusion(db_session: Session):
    """Verify estimate is included only when requested AND status is 'estimate'."""
    user = _create_user(db_session)
    cycle_repo = CycleRepository(db_session)

    # 4 consecutive 28-day periods
    for start in [date(2026, 1, 1), date(2026, 1, 29), date(2026, 2, 26), date(2026, 3, 26)]:
        cycle_repo.create_cycle_log(user.id, start)

    collector = DoctorSummaryCollectorService(db_session)

    # include.estimate = False -> estimate is None
    req_no_est = DoctorSummaryRequest(
        from_date=date(2026, 3, 1),
        to_date=date(2026, 3, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False, estimate=False),
    )
    data_no_est = collector.collect_summary_data(user.id, req_no_est)
    assert data_no_est.estimate is None
    assert "Cycle estimate" not in data_no_est.included_categories

    # include.estimate = True -> estimate included
    req_with_est = DoctorSummaryRequest(
        from_date=date(2026, 3, 1),
        to_date=date(2026, 3, 30),
        include=DoctorSummaryInclude(periods=True, symptoms=False, estimate=True),
    )
    data_with_est = collector.collect_summary_data(user.id, req_with_est)
    assert data_with_est.estimate is not None
    assert data_with_est.estimate.status == "estimate"
    assert data_with_est.estimate.typical_cycle_length_days == 28
    assert "Cycle estimate" in data_with_est.included_categories


def test_doctor_summary_collector_two_account_isolation(db_session: Session):
    """
    CRITICAL ISOLATION TEST:
    User A's collected summary data must NEVER contain User B's cycle logs,
    symptoms, custom labels, notes, or dates under any circumstances.
    """
    user_a = _create_user(db_session, "user_a")
    user_b = _create_user(db_session, "user_b")

    cycle_repo = CycleRepository(db_session)
    symptom_repo = SymptomRepository(db_session)

    # Seed User A data
    cycle_repo.create_cycle_log(user_a.id, date(2026, 1, 1), date(2026, 1, 5))
    symptom_repo.create_symptom_log(
        user_a.id, date(2026, 1, 2), "cramps", 2, custom_label="USER_A_CRAMP", notes="USER_A_PRIVATE_NOTE"
    )

    # Seed User B data with unique marker strings
    cycle_repo.create_cycle_log(user_b.id, date(2026, 1, 3), date(2026, 1, 8))
    symptom_repo.create_symptom_log(
        user_b.id,
        date(2026, 1, 4),
        "bloating",
        4,
        custom_label="USER_B_SECRET_LABEL_999",
        notes="USER_B_SECRET_NOTE_CONFIDENTIAL_888",
    )

    collector = DoctorSummaryCollectorService(db_session)
    req = DoctorSummaryRequest(
        from_date=date(2026, 1, 1),
        to_date=date(2026, 1, 10),
        include=DoctorSummaryInclude(periods=True, symptoms=True, symptom_notes=True),
    )

    data_a = collector.collect_summary_data(user_a.id, req)

    # Verify User A data presence
    assert len(data_a.periods) == 1
    assert data_a.periods[0].period_start == date(2026, 1, 1)
    assert len(data_a.symptoms) == 1
    assert data_a.symptoms[0].custom_label == "USER_A_CRAMP"
    assert "USER_A_PRIVATE_NOTE" in data_a.symptoms[0].notes

    # Assert ZERO trace of User B's data
    for p in data_a.periods:
        assert p.period_start != date(2026, 1, 3)
    for s in data_a.symptoms:
        assert s.symptom_type != "bloating"
        assert s.custom_label != "USER_B_SECRET_LABEL_999"
        for note in s.notes:
            assert "USER_B" not in note
            assert "CONFIDENTIAL" not in note


def test_doctor_summary_collector_symptom_cap_exceeded(db_session: Session):
    """Verify that exceeding DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS raises SummaryTooLargeError (413)."""
    user = _create_user(db_session)
    symptom_repo = SymptomRepository(db_session)

    collector = DoctorSummaryCollectorService(db_session)

    # Insert rows directly or monkeypatch count to test the cap threshold
    # Since default limit is 500, we mock count_symptoms_in_range to return 501
    original_count = symptom_repo.count_symptoms_in_range
    try:
        symptom_repo.count_symptoms_in_range = lambda *args, **kwargs: settings.DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS + 1
        collector.symptom_repo = symptom_repo

        req = DoctorSummaryRequest(
            from_date=date(2026, 1, 1),
            to_date=date(2026, 1, 30),
            include=DoctorSummaryInclude(periods=False, symptoms=True),
        )

        with pytest.raises(SummaryTooLargeError) as exc_info:
            collector.collect_summary_data(user.id, req)
        assert exc_info.value.status_code == 413
        assert "summary_too_large" in str(exc_info.value.detail)
    finally:
        symptom_repo.count_symptoms_in_range = original_count
