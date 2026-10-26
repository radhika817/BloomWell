from collections import defaultdict
from datetime import date, timedelta
from typing import Dict, List, Optional
import uuid
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.activity import Activity, UserActivityLog
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.study_plan import (
    PlanItemStatus,
    StudyPlan,
    StudyPlanItem,
    StudyPlanMode,
    SuggestedLoad,
)
from app.repositories.study_plan_repository import StudyPlanRepository
from app.repositories.user_repository import UserRepository
from app.schemas.study_plan import (
    PersonalizationInfo,
    StudyPlanItemPatchRequest,
    StudyPlanItemResponse,
    StudyPlanResponse,
)
from app.services.planner_algorithm import (
    AcademicEventInput,
    ActivityCandidate,
    CycleRecordInput,
    generate_study_plan_schedule,
)


def _to_plan_response(plan: StudyPlan) -> StudyPlanResponse:
    items_sorted = sorted(plan.items, key=lambda it: it.plan_date)
    return StudyPlanResponse(
        id=plan.id,
        week_start=plan.week_start,
        days=plan.days,
        mode=plan.mode,
        uses_cycle_data=plan.uses_cycle_data,
        personalization=PersonalizationInfo(
            status=plan.mode,  # "default" or "personalized"
            checkin_days_used=plan.checkin_days_used,
            checkin_days_needed=14,
        ),
        items=[
            StudyPlanItemResponse(
                id=item.id,
                study_plan_id=item.study_plan_id,
                plan_date=item.plan_date,
                suggested_load=item.suggested_load,
                reason_codes=item.reason_codes,
                academic_event_id=item.academic_event_id,
                activity_id=item.activity_id,
                status=item.status,
                updated_at=item.updated_at,
            )
            for item in items_sorted
        ],
        created_at=plan.created_at,
    )


class PlannerService:
    """Service orchestrating study plan generation, retrieval, and item updates."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self.plan_repo = StudyPlanRepository(db)
        self.user_repo = UserRepository(db)

    def generate_plan(
        self,
        user_id: uuid.UUID,
        week_start: date,
        replace: bool = False,
    ) -> StudyPlanResponse:
        """
        Generate a 7-day study plan covering week_start.
        Returns 409 plan_exists if plan exists and replace is False.
        """
        existing_plan = self.plan_repo.get_by_week(user_id=user_id, week_start=week_start)
        if existing_plan:
            if not replace:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "code": "plan_exists",
                        "message": "A study plan already exists for this week. Set replace=true to regenerate.",
                    },
                )
            self.plan_repo.delete_plan_by_week(user_id=user_id, week_start=week_start)

        # 1. Gather check-in energy history for the past 28 days
        history_start = week_start - timedelta(days=28)
        history_end = week_start - timedelta(days=1)
        checkin_stmt = (
            select(MoodCheckin)
            .where(
                MoodCheckin.user_id == user_id,
                MoodCheckin.local_date >= history_start,
                MoodCheckin.local_date <= history_end,
            )
        )
        checkins = list(self.db.scalars(checkin_stmt).all())

        checkins_by_date: Dict[date, List[int]] = defaultdict(list)
        for c in checkins:
            checkins_by_date[c.local_date].append(c.energy_score)

        daily_energy_history: Dict[date, float] = {
            d: sum(scores) / len(scores) for d, scores in checkins_by_date.items()
        }

        # 2. Gather academic events from plan start through 14 days after plan end
        # Plan window is 7 days: week_start through week_start + 6.
        # 14 days after plan end = week_start + 20 days.
        event_end = week_start + timedelta(days=20)
        event_stmt = (
            select(AcademicEvent)
            .where(
                AcademicEvent.user_id == user_id,
                AcademicEvent.event_date >= week_start,
                AcademicEvent.event_date <= event_end,
            )
        )
        db_events = list(self.db.scalars(event_stmt).all())
        academic_events = [
            AcademicEventInput(
                id=ev.id,
                event_date=ev.event_date,
                title=ev.title,
                event_type=ev.event_type,
            )
            for ev in db_events
        ]

        # 3. Preferences and cycle consent check
        pref = self.user_repo.get_preferences(user_id)
        cycle_consent = bool(pref and pref.planner_cycle_consent_at is not None)
        cycle_tracking = bool(pref and pref.cycle_tracking_enabled)

        recorded_cycles: List[CycleRecordInput] = []
        if cycle_consent and cycle_tracking:
            cycle_stmt = (
                select(CycleLog)
                .where(CycleLog.user_id == user_id)
                .order_by(CycleLog.period_start.desc())
                .limit(6)
            )
            db_cycles = list(self.db.scalars(cycle_stmt).all())
            # Restore chronological order
            db_cycles.reverse()
            recorded_cycles = [
                CycleRecordInput(
                    period_start=c.period_start,
                    period_end=c.period_end,
                )
                for c in db_cycles
            ]

        # 4. Published study break activities and user favorites
        act_stmt = (
            select(Activity)
            .where(
                Activity.category == "study_break",
                Activity.is_published.is_(True),
            )
        )
        db_activities = list(self.db.scalars(act_stmt).all())

        # Check favorites
        fav_stmt = (
            select(UserActivityLog.activity_id)
            .where(
                UserActivityLog.user_id == user_id,
                UserActivityLog.is_favorite.is_(True),
            )
        )
        favorite_ids = set(self.db.scalars(fav_stmt).all())

        activity_candidates = [
            ActivityCandidate(
                id=act.id,
                is_favorite=(act.id in favorite_ids),
                is_published=act.is_published,
                category=act.category,
            )
            for act in db_activities
        ]

        # 5. Call pure deterministic algorithm
        output = generate_study_plan_schedule(
            week_start=week_start,
            daily_energy_history=daily_energy_history,
            academic_events=academic_events,
            cycle_consent=cycle_consent,
            cycle_tracking_enabled=cycle_tracking,
            recorded_cycles=recorded_cycles,
            break_activities=activity_candidates,
        )

        # 6. Persist plan and plan items
        new_plan = StudyPlan(
            user_id=user_id,
            week_start=output.week_start,
            days=output.days,
            mode=output.mode,
            uses_cycle_data=output.uses_cycle_data,
            checkin_days_used=output.checkin_days_used,
        )
        for item_data in output.items:
            new_item = StudyPlanItem(
                plan_date=item_data.plan_date,
                suggested_load=item_data.suggested_load,
                reason_codes=item_data.reason_codes,
                academic_event_id=item_data.academic_event_id,
                activity_id=item_data.activity_id,
                status=PlanItemStatus.SUGGESTED.value,
            )
            new_plan.items.append(new_item)

        created_plan = self.plan_repo.create_plan(user_id=user_id, plan=new_plan)
        return _to_plan_response(created_plan)

    def get_current_plan(self, user_id: uuid.UUID) -> StudyPlanResponse:
        """Retrieve study plan covering today for user_id."""
        plan = self.plan_repo.get_current_plan(user_id=user_id, today=date.today())
        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No study plan found for the current week.",
            )
        return _to_plan_response(plan)

    def get_plan_by_week_or_id(
        self,
        user_id: uuid.UUID,
        plan_id: Optional[uuid.UUID] = None,
        week_start: Optional[date] = None,
    ) -> StudyPlanResponse:
        """Retrieve study plan by id or week_start for user_id."""
        plan = None
        if plan_id:
            plan = self.plan_repo.get_by_id(user_id=user_id, plan_id=plan_id)
        elif week_start:
            plan = self.plan_repo.get_by_week(user_id=user_id, week_start=week_start)

        if not plan:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study plan not found.",
            )
        return _to_plan_response(plan)

    def delete_plan(self, user_id: uuid.UUID, plan_id: uuid.UUID) -> None:
        """Delete study plan strictly scoped to user_id."""
        success = self.plan_repo.delete_plan(user_id=user_id, plan_id=plan_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study plan not found.",
            )

    def patch_item(
        self,
        user_id: uuid.UUID,
        item_id: uuid.UUID,
        req: StudyPlanItemPatchRequest,
    ) -> StudyPlanItemResponse:
        """
        Update status and optionally suggested_load.
        suggested_load allowed only when status is 'edited'.
        """
        if req.suggested_load is not None and req.status != "edited":
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="suggested_load is only allowed when status is 'edited'.",
            )

        item = self.plan_repo.update_item(
            user_id=user_id,
            item_id=item_id,
            status=req.status,
            suggested_load=req.suggested_load,
        )
        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Study plan item not found.",
            )

        return StudyPlanItemResponse(
            id=item.id,
            study_plan_id=item.study_plan_id,
            plan_date=item.plan_date,
            suggested_load=item.suggested_load,
            reason_codes=item.reason_codes,
            academic_event_id=item.academic_event_id,
            activity_id=item.activity_id,
            status=item.status,
            updated_at=item.updated_at,
        )
