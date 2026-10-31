import uuid
from typing import Callable, Dict, List, Set
from sqlalchemy import delete, select, update
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.account_event import AccountEvent
from app.models.activity import UserActivityLog
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.journal import JournalEntry
from app.models.preference import UserPreference
from app.models.resource import ResourceReport
from app.models.study_plan import StudyPlan, StudyPlanItem
from app.models.token import RefreshToken
from app.models.user import User

DeleterFunc = Callable[[Session, uuid.UUID], None]


class DeletionRegistry:
    """
    Extensible, registry-driven routine ensuring explicit deletion
    from every user-owned table in a single database transaction.
    """

    def __init__(self) -> None:
        self._deleters: Dict[str, DeleterFunc] = {}

    def register(self, table_name: str, deleter: DeleterFunc) -> None:
        """Register a table-specific deletion handler."""
        self._deleters[table_name] = deleter

    def get_registered_tables(self) -> Set[str]:
        """Return all table names covered by the deletion registry."""
        return set(self._deleters.keys())

    def delete_user_account(self, db: Session, user_id: uuid.UUID) -> None:
        """
        Execute atomic account deletion within a single transaction:
        1. Revoke/delete all refresh tokens.
        2. Run all registered table deleters.
        3. Delete user row.
        Rolls back completely if any step fails.
        """
        user = db.scalars(select(User).where(User.id == user_id)).first()
        if not user:
            raise ValueError("User not found.")

        # Execute inside a savepoint / nested transaction for strict rollback integrity
        with db.begin_nested():
            # Expire session cached state of user child objects so raw deletes don't conflict with ORM cascade
            db.expire(user)

            # Run registered deleters in order
            for table_name, deleter in self._deleters.items():
                deleter(db, user_id)

            # Delete user record (will also cascade account_events and any remaining cascade foreign keys)
            db.delete(user)
            db.flush()

        db.commit()


# Global deletion registry instance
deletion_registry = DeletionRegistry()


# --- Table Deleter Implementations ---


def _delete_refresh_tokens(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(RefreshToken).where(RefreshToken.user_id == user_id))


def _delete_user_preferences(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(UserPreference).where(UserPreference.user_id == user_id))


def _delete_mood_checkins(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(MoodCheckin).where(MoodCheckin.user_id == user_id))


def _delete_journal_entries(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(JournalEntry).where(JournalEntry.user_id == user_id))


def _delete_academic_events(db: Session, user_id: uuid.UUID) -> None:
    # First nullify study_plan_items academic_event references if needed, then delete academic events
    db.execute(
        update(StudyPlanItem)
        .where(
            StudyPlanItem.academic_event_id.in_(
                select(AcademicEvent.id).where(AcademicEvent.user_id == user_id)
            )
        )
        .values(academic_event_id=None)
    )
    db.execute(delete(AcademicEvent).where(AcademicEvent.user_id == user_id))


def _delete_user_activity_logs(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(UserActivityLog).where(UserActivityLog.user_id == user_id))


def _delete_cycle_logs(db: Session, user_id: uuid.UUID) -> None:
    db.execute(delete(CycleLog).where(CycleLog.user_id == user_id))


def _delete_study_plans(db: Session, user_id: uuid.UUID) -> None:
    # Delete study_plan_items child records then study_plans
    plan_ids = select(StudyPlan.id).where(StudyPlan.user_id == user_id)
    db.execute(delete(StudyPlanItem).where(StudyPlanItem.study_plan_id.in_(plan_ids)))
    db.execute(delete(StudyPlan).where(StudyPlan.user_id == user_id))


def _delete_resource_reports(db: Session, user_id: uuid.UUID) -> None:
    # Requirement: resource_reports keep their rows but lose the reporter link (reporter_id becomes null)
    db.execute(
        update(ResourceReport)
        .where(ResourceReport.reporter_id == user_id)
        .values(reporter_id=None)
    )


# Register all user-owned tables
deletion_registry.register("refresh_tokens", _delete_refresh_tokens)
deletion_registry.register("user_preferences", _delete_user_preferences)
deletion_registry.register("mood_checkins", _delete_mood_checkins)
deletion_registry.register("journal_entries", _delete_journal_entries)
deletion_registry.register("academic_events", _delete_academic_events)
deletion_registry.register("user_activity_logs", _delete_user_activity_logs)
deletion_registry.register("cycle_logs", _delete_cycle_logs)
deletion_registry.register("study_plans", _delete_study_plans)
deletion_registry.register("resource_reports", _delete_resource_reports)
