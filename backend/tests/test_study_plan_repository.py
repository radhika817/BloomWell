import uuid
from datetime import date, timedelta
import pytest
from sqlalchemy.orm import Session

from app.models.study_plan import (
    PlanItemStatus,
    StudyPlan,
    StudyPlanItem,
    StudyPlanMode,
    SuggestedLoad,
)
from app.models.user import User
from app.repositories.study_plan_repository import StudyPlanRepository


def test_study_plan_repository_owner_scoping_and_joins(db_session: Session):
    """Test owner-scoped queries and verify items are joined through study_plans.user_id."""
    user_a = User(email="repo.a@campus.edu", password_hash="hash_a", display_name="A")
    user_b = User(email="repo.b@campus.edu", password_hash="hash_b", display_name="B")
    db_session.add_all([user_a, user_b])
    db_session.commit()

    repo = StudyPlanRepository(db_session)
    week_start = date(2026, 11, 2)

    # User A creates plan
    plan_a = StudyPlan(
        week_start=week_start,
        days=7,
        mode=StudyPlanMode.PERSONALIZED.value,
        uses_cycle_data=False,
        checkin_days_used=15,
    )
    repo.create_plan(user_id=user_a.id, plan=plan_a)

    item_a = StudyPlanItem(
        study_plan_id=plan_a.id,
        plan_date=week_start,
        suggested_load=SuggestedLoad.NORMAL.value,
        reason_codes=["DEFAULT_PLAN"],
        status=PlanItemStatus.SUGGESTED.value,
    )
    db_session.add(item_a)
    db_session.commit()

    # 1. User A can retrieve plan and item
    fetched_plan = repo.get_by_id(user_id=user_a.id, plan_id=plan_a.id)
    assert fetched_plan is not None
    assert fetched_plan.id == plan_a.id

    fetched_item = repo.get_item_by_id(user_id=user_a.id, item_id=item_a.id)
    assert fetched_item is not None
    assert fetched_item.id == item_a.id

    # 2. User B cannot retrieve User A's plan or item (isolation)
    assert repo.get_by_id(user_id=user_b.id, plan_id=plan_a.id) is None
    assert repo.get_item_by_id(user_id=user_b.id, item_id=item_a.id) is None

    # 3. User B cannot update User A's item
    updated = repo.update_item(
        user_id=user_b.id,
        item_id=item_a.id,
        status=PlanItemStatus.ACCEPTED.value,
    )
    assert updated is None
    db_session.refresh(item_a)
    assert item_a.status == PlanItemStatus.SUGGESTED.value

    # 4. User A updates item status
    updated_a = repo.update_item(
        user_id=user_a.id,
        item_id=item_a.id,
        status=PlanItemStatus.ACCEPTED.value,
        suggested_load=SuggestedLoad.FOCUS.value,
    )
    assert updated_a is not None
    assert updated_a.status == PlanItemStatus.ACCEPTED.value
    assert updated_a.suggested_load == SuggestedLoad.FOCUS.value

    # 5. Current plan detection
    today_in_plan = week_start + timedelta(days=3)
    current = repo.get_current_plan(user_id=user_a.id, today=today_in_plan)
    assert current is not None
    assert current.id == plan_a.id

    today_outside_plan = week_start + timedelta(days=10)
    assert repo.get_current_plan(user_id=user_a.id, today=today_outside_plan) is None
    assert repo.get_current_plan(user_id=user_b.id, today=today_in_plan) is None
