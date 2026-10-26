import uuid
from datetime import date, datetime, timezone
import pytest
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.activity import Activity, UserActivityLog
from app.models.cycle import CycleLog
from app.models.user import User
from app.models.preference import UserPreference


def test_prerequisite_models_creation_and_relationships(db_session: Session):
    """Test creation and cascade relationships for prerequisite models."""
    user = User(
        email="prereq.test@campus.edu",
        password_hash="fake_hash_123456",
        display_name="Prereq Test User",
    )
    pref = UserPreference(
        user=user,
        cycle_tracking_enabled=True,
        cycle_tracking_consent_at=datetime.now(timezone.utc),
    )
    db_session.add(user)
    db_session.add(pref)
    db_session.commit()

    # Create academic event
    event = AcademicEvent(
        user_id=user.id,
        title="Midterm Biology",
        event_date=date(2026, 11, 10),
        event_type="exam",
    )
    db_session.add(event)

    # Create activity
    act = Activity(
        title="Mindful Breathing",
        category="study_break",
        duration_minutes=5,
        content="Take 5 slow breaths.",
        language="en",
        is_published=True,
    )
    db_session.add(act)
    db_session.commit()

    # Create activity log
    act_log = UserActivityLog(
        user_id=user.id,
        activity_id=act.id,
        is_favorite=True,
        helpfulness_rating=5,
    )
    db_session.add(act_log)

    # Create cycle log
    cycle = CycleLog(
        user_id=user.id,
        period_start=date(2026, 10, 1),
        period_end=date(2026, 10, 5),
    )
    db_session.add(cycle)
    db_session.commit()

    # Query and assert
    assert len(user.academic_events) == 1
    assert user.academic_events[0].title == "Midterm Biology"
    assert len(user.cycle_logs) == 1
    assert user.cycle_logs[0].period_start == date(2026, 10, 1)
    assert len(user.activity_logs) == 1
    assert user.activity_logs[0].is_favorite is True
    assert user.preferences.cycle_tracking_enabled is True
    assert user.preferences.cycle_tracking_consent_at is not None
