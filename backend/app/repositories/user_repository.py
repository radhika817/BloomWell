import uuid
from typing import Any, Dict, Optional
from sqlalchemy import select, delete
from sqlalchemy.orm import Session, joinedload

from app.models.preference import UserPreference
from app.models.user import User


class UserRepository:
    """
    Data repository for User and UserPreference records.
    Enforces explicit user_id scoping on all private operations.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, user_id: uuid.UUID) -> Optional[User]:
        """Fetch active user by explicit user_id with preferences loaded."""
        stmt = (
            select(User)
            .options(joinedload(User.preferences))
            .where(User.id == user_id, User.deleted_at.is_(None))
        )
        return self.db.scalars(stmt).first()

    def get_by_email(self, email: str) -> Optional[User]:
        """Fetch active user by normalized email with preferences loaded."""
        normalized_email = email.strip().lower()
        stmt = (
            select(User)
            .options(joinedload(User.preferences))
            .where(User.email == normalized_email, User.deleted_at.is_(None))
        )
        return self.db.scalars(stmt).first()

    def create(
        self,
        email: str,
        password_hash: str,
        display_name: Optional[str] = None,
        timezone: str = "UTC",
    ) -> User:
        """
        Create a new user and an associated user_preferences row with safe defaults.
        Defaults: language='en', discreet_notifications=True, AI flags off, consents null.
        """
        normalized_email = email.strip().lower()
        user = User(
            id=uuid.uuid4(),
            email=normalized_email,
            password_hash=password_hash,
            display_name=display_name.strip() if display_name else None,
            role="student",
        )
        preferences = UserPreference(
            user_id=user.id,
            timezone=timezone,
            language="en",
            reminders_enabled=True,
            discreet_notifications=True,
            ai_recommendations_enabled=False,
            journal_ai_consent_at=None,
            planner_cycle_consent_at=None,
        )
        user.preferences = preferences

        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        return user

    def get_preferences(self, user_id: uuid.UUID) -> Optional[UserPreference]:
        """Fetch user preferences explicitly scoped by user_id."""
        stmt = select(UserPreference).where(UserPreference.user_id == user_id)
        return self.db.scalars(stmt).first()

    def update_preferences(
        self,
        user_id: uuid.UUID,
        updates: Dict[str, Any],
    ) -> UserPreference:
        """
        Update whitelisted preferences for a user, explicitly scoped by user_id.
        """
        stmt = select(UserPreference).where(UserPreference.user_id == user_id)
        pref = self.db.scalars(stmt).first()

        if not pref:
            pref = UserPreference(user_id=user_id, **updates)
            self.db.add(pref)
        else:
            for key, value in updates.items():
                if hasattr(pref, key) and value is not None:
                    setattr(pref, key, value)

        self.db.commit()
        self.db.refresh(pref)
        return pref

    def set_planner_cycle_consent(
        self,
        user_id: uuid.UUID,
        enabled: bool,
    ) -> tuple[UserPreference, int]:
        """
        Update planner cycle consent.
        If disabling, deletes all cycle-derived study plans in the same transaction.
        Returns (preferences, deleted_plans_count).
        """
        from datetime import datetime, timezone
        from app.models.study_plan import StudyPlan

        stmt = select(UserPreference).where(UserPreference.user_id == user_id)
        pref = self.db.scalars(stmt).first()
        if not pref:
            pref = UserPreference(user_id=user_id)
            self.db.add(pref)

        deleted_plans_count = 0
        if enabled:
            pref.planner_cycle_consent_at = datetime.now(timezone.utc)
        else:
            pref.planner_cycle_consent_at = None
            # Transactionally delete cycle-derived study plans
            plans = list(
                self.db.scalars(
                    select(StudyPlan).where(
                        StudyPlan.user_id == user_id,
                        StudyPlan.uses_cycle_data.is_(True),
                    )
                ).all()
            )
            deleted_plans_count = len(plans)
            for p in plans:
                self.db.delete(p)

        self.db.commit()
        self.db.refresh(pref)
        return pref, deleted_plans_count

    def set_cycle_tracking(
        self,
        user_id: uuid.UUID,
        enabled: bool,
        delete_data: bool = False,
    ) -> tuple[UserPreference, int, int]:
        """
        Update cycle tracking status and optionally delete cycle logs and cycle-derived study plans.
        Disabling tracking or deleting cycle data transactionally deletes all of the user's
        study plans where uses_cycle_data is true.
        Returns (preferences, deleted_plans_count, deleted_cycles_count).
        """
        from datetime import datetime, timezone
        from app.models.cycle import CycleLog
        from app.models.study_plan import StudyPlan

        stmt = select(UserPreference).where(UserPreference.user_id == user_id)
        pref = self.db.scalars(stmt).first()
        if not pref:
            pref = UserPreference(user_id=user_id)
            self.db.add(pref)

        deleted_plans_count = 0
        deleted_cycles_count = 0

        if enabled:
            pref.cycle_tracking_enabled = True
            pref.cycle_tracking_consent_at = datetime.now(timezone.utc)
        else:
            pref.cycle_tracking_enabled = False
            pref.cycle_tracking_consent_at = None
            # Disabling cycle tracking also clears planner cycle consent
            pref.planner_cycle_consent_at = None

        if not enabled or delete_data:
            # Transactionally delete all cycle-derived study plans
            plans = list(
                self.db.scalars(
                    select(StudyPlan).where(
                        StudyPlan.user_id == user_id,
                        StudyPlan.uses_cycle_data.is_(True),
                    )
                ).all()
            )
            deleted_plans_count = len(plans)
            for p in plans:
                self.db.delete(p)

        if delete_data:
            # Transactionally delete recorded cycle logs
            cycles = list(
                self.db.scalars(
                    select(CycleLog).where(CycleLog.user_id == user_id)
                ).all()
            )
            deleted_cycles_count = len(cycles)
            for c in cycles:
                self.db.delete(c)

        self.db.commit()
        self.db.refresh(pref)
        return pref, deleted_plans_count, deleted_cycles_count

