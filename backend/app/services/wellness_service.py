import uuid
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo
from sqlalchemy.orm import Session

from app.models.checkin import MoodCheckin
from app.repositories.checkin_repository import CheckinRepository
from app.repositories.user_repository import UserRepository


class WellnessService:
    """
    Domain service for student wellness check-ins.
    Enforces privacy, owner scoping, client idempotency, and calendar bounds.
    """

    def __init__(self, db: Session) -> None:
        self.db = db
        self.checkin_repo = CheckinRepository(db)
        self.user_repo = UserRepository(db)

    def record_checkin(
        self,
        user_id: uuid.UUID,
        client_id: uuid.UUID,
        local_date: date,
        mood_score: int,
        stress_score: int,
        energy_score: int,
        sleep_quality_score: Optional[int] = None,
        mood_label: Optional[str] = None,
        tags: Optional[List[str]] = None,
        notes: Optional[str] = None,
    ) -> Tuple[MoodCheckin, bool]:
        """
        Record a mood check-in.
        Returns: (checkin, created)
          - If client_id already exists for this user, returns (existing_checkin, False) for idempotency (200 OK).
          - If newly created, returns (new_checkin, True) (201 Created).
        """
        # Validate date is not more than 1 day in the future relative to user's timezone
        user = self.user_repo.get_by_id(user_id)
        tz_name = user.preferences.timezone if (user and user.preferences and user.preferences.timezone) else "UTC"
        try:
            user_tz = ZoneInfo(tz_name)
        except Exception:
            user_tz = ZoneInfo("UTC")

        today_in_tz = datetime.now(user_tz).date()
        max_allowed_date = today_in_tz + timedelta(days=1)
        if local_date > max_allowed_date:
            raise ValueError(
                f"Check-in date '{local_date}' cannot be more than 1 day in the future (max allowed: {max_allowed_date})."
            )

        # Idempotency check: if client_id already recorded for this user, return existing record
        existing = self.checkin_repo.get_by_client_id(user_id=user_id, client_id=client_id)
        if existing:
            return existing, False

        checkin = self.checkin_repo.create(
            user_id=user_id,
            client_id=client_id,
            local_date=local_date,
            mood_score=mood_score,
            stress_score=stress_score,
            energy_score=energy_score,
            sleep_quality_score=sleep_quality_score,
            mood_label=mood_label,
            tags=tags,
            notes=notes,
        )
        return checkin, True

    def get_checkin(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
    ) -> Optional[MoodCheckin]:
        """Fetch a check-in strictly scoped to user_id. Returns None if not found."""
        return self.checkin_repo.get_by_id(user_id=user_id, checkin_id=checkin_id)

    def list_checkins(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> Tuple[List[MoodCheckin], Optional[str], bool]:
        """List check-ins for user_id with pagination and optional date filters."""
        limit = max(1, min(limit, 100))
        if from_date and to_date and from_date > to_date:
            raise ValueError("from_date cannot be after to_date.")

        return self.checkin_repo.list(
            user_id=user_id,
            limit=limit,
            cursor=cursor,
            from_date=from_date,
            to_date=to_date,
        )

    def update_checkin(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
        updates: Dict[str, Any],
    ) -> Optional[MoodCheckin]:
        """Update check-in attributes strictly scoped to user_id."""
        return self.checkin_repo.update(
            user_id=user_id,
            checkin_id=checkin_id,
            updates=updates,
        )

    def delete_checkin(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
    ) -> bool:
        """Delete check-in strictly scoped to user_id."""
        return self.checkin_repo.delete(user_id=user_id, checkin_id=checkin_id)
