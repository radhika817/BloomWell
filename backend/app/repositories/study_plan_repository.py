from datetime import date, timedelta
from typing import Optional
import uuid
from sqlalchemy import delete, select
from sqlalchemy.orm import Session, selectinload

from app.models.study_plan import StudyPlan, StudyPlanItem


class StudyPlanRepository:
    """
    Owner-scoped repository for StudyPlan and StudyPlanItem entities.
    CRITICAL ARCHITECTURAL RULE: Every method takes an explicit user_id and filters by it.
    StudyPlanItem entities are accessed ONLY through a join on study_plans.user_id.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, user_id: uuid.UUID, plan_id: uuid.UUID) -> Optional[StudyPlan]:
        """Fetch study plan by id strictly scoped to the owner."""
        stmt = (
            select(StudyPlan)
            .options(selectinload(StudyPlan.items))
            .where(StudyPlan.id == plan_id, StudyPlan.user_id == user_id)
        )
        return self.db.scalars(stmt).first()

    def get_by_week(self, user_id: uuid.UUID, week_start: date) -> Optional[StudyPlan]:
        """Fetch study plan for a given week start strictly scoped to the owner."""
        stmt = (
            select(StudyPlan)
            .options(selectinload(StudyPlan.items))
            .where(StudyPlan.week_start == week_start, StudyPlan.user_id == user_id)
        )
        return self.db.scalars(stmt).first()

    def get_current_plan(self, user_id: uuid.UUID, today: date) -> Optional[StudyPlan]:
        """Fetch the study plan that covers today for the owner."""
        stmt = (
            select(StudyPlan)
            .options(selectinload(StudyPlan.items))
            .where(
                StudyPlan.user_id == user_id,
                StudyPlan.week_start <= today,
            )
            .order_by(StudyPlan.week_start.desc())
        )
        plans = list(self.db.scalars(stmt).all())
        for plan in plans:
            plan_end = plan.week_start + timedelta(days=plan.days - 1)
            if plan.week_start <= today <= plan_end:
                return plan
        return None

    def create_plan(self, user_id: uuid.UUID, plan: StudyPlan) -> StudyPlan:
        """Create and persist a new study plan scoped to user_id."""
        plan.user_id = user_id
        self.db.add(plan)
        self.db.commit()
        self.db.refresh(plan)
        return plan

    def delete_plan(self, user_id: uuid.UUID, plan_id: uuid.UUID) -> bool:
        """Delete a study plan strictly scoped to the owner."""
        plan = self.get_by_id(user_id=user_id, plan_id=plan_id)
        if not plan:
            return False
        self.db.delete(plan)
        self.db.commit()
        return True

    def delete_plan_by_week(self, user_id: uuid.UUID, week_start: date) -> bool:
        """Delete an existing plan for a week, used during replacement."""
        plan = self.get_by_week(user_id=user_id, week_start=week_start)
        if not plan:
            return False
        self.db.delete(plan)
        self.db.commit()
        return True

    def get_item_by_id(self, user_id: uuid.UUID, item_id: uuid.UUID) -> Optional[StudyPlanItem]:
        """
        Fetch a study plan item reached ONLY through a join on study_plans.user_id.
        Guarantees cross-account access cannot read items.
        """
        stmt = (
            select(StudyPlanItem)
            .join(StudyPlan, StudyPlanItem.study_plan_id == StudyPlan.id)
            .where(StudyPlanItem.id == item_id, StudyPlan.user_id == user_id)
        )
        return self.db.scalars(stmt).first()

    def update_item(
        self,
        user_id: uuid.UUID,
        item_id: uuid.UUID,
        status: Optional[str] = None,
        suggested_load: Optional[str] = None,
    ) -> Optional[StudyPlanItem]:
        """
        Update status or suggested_load on a study plan item owned by user_id.
        Item reached strictly through join on study_plans.user_id.
        """
        item = self.get_item_by_id(user_id=user_id, item_id=item_id)
        if not item:
            return None

        if status is not None:
            item.status = status
        if suggested_load is not None:
            item.suggested_load = suggested_load

        self.db.commit()
        self.db.refresh(item)
        return item
