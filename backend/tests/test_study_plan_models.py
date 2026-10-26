import uuid
from datetime import date
import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.activity import Activity
from app.models.study_plan import (
    StudyPlan,
    StudyPlanItem,
    StudyPlanMode,
    SuggestedLoad,
    PlanItemStatus,
)
from app.models.user import User


def test_study_plan_creation_and_cascade(db_session: Session):
    """Test StudyPlan and StudyPlanItem creation and cascade deletion."""
    user = User(
        email="plan.model@campus.edu",
        password_hash="fake_hash_123456",
        display_name="Plan User",
    )
    db_session.add(user)
    db_session.commit()

    event = AcademicEvent(
        user_id=user.id,
        title="Physics Exam",
        event_date=date(2026, 11, 20),
    )
    act = Activity(
        title="Gentle Stretch",
        category="study_break",
        duration_minutes=5,
        content="Stretch arms and shoulders.",
        language="en",
    )
    db_session.add_all([event, act])
    db_session.commit()

    plan = StudyPlan(
        user_id=user.id,
        week_start=date(2026, 11, 16),
        days=7,
        mode=StudyPlanMode.PERSONALIZED.value,
        uses_cycle_data=False,
        checkin_days_used=14,
    )
    db_session.add(plan)
    db_session.commit()

    item = StudyPlanItem(
        study_plan_id=plan.id,
        plan_date=date(2026, 11, 16),
        suggested_load=SuggestedLoad.FOCUS.value,
        reason_codes=["WEEKDAY_ENERGY_HIGHER"],
        academic_event_id=event.id,
        activity_id=act.id,
        status=PlanItemStatus.SUGGESTED.value,
    )
    db_session.add(item)
    db_session.commit()

    # Verify query
    saved_plan = db_session.get(StudyPlan, plan.id)
    assert saved_plan is not None
    assert len(saved_plan.items) == 1
    assert saved_plan.items[0].suggested_load == "focus"
    assert saved_plan.items[0].academic_event_id == event.id
    assert saved_plan.items[0].activity_id == act.id

    # Test SET NULL on activity deletion
    db_session.delete(act)
    db_session.commit()
    db_session.refresh(item)
    assert item.activity_id is None

    # Test cascade delete from StudyPlan
    db_session.delete(saved_plan)
    db_session.commit()
    assert db_session.get(StudyPlanItem, item.id) is None


def test_study_plan_unique_constraints(db_session: Session):
    """Test unique constraint on (user_id, week_start)."""
    user = User(
        email="unique.plan@campus.edu",
        password_hash="fake_hash_123456",
        display_name="Unique User",
    )
    db_session.add(user)
    db_session.commit()

    plan1 = StudyPlan(
        user_id=user.id,
        week_start=date(2026, 11, 23),
    )
    db_session.add(plan1)
    db_session.commit()

    plan2 = StudyPlan(
        user_id=user.id,
        week_start=date(2026, 11, 23),
    )
    db_session.add(plan2)
    with pytest.raises(IntegrityError):
        db_session.commit()
    db_session.rollback()
