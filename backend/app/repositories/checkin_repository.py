import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.core.pagination import decode_cursor, encode_cursor
from app.models.checkin import MoodCheckin


class CheckinRepository:
    """
    Owner-scoped repository for MoodCheckin records.
    Every method requires an explicit user_id and filters strictly by it.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
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
    ) -> MoodCheckin:
        """Create a new mood check-in strictly scoped to user_id."""
        checkin = MoodCheckin(
            id=uuid.uuid4(),
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
        self.db.add(checkin)
        self.db.commit()
        self.db.refresh(checkin)
        return checkin

    def get_by_client_id(
        self,
        user_id: uuid.UUID,
        client_id: uuid.UUID,
    ) -> Optional[MoodCheckin]:
        """Fetch checkin by client_id strictly scoped to user_id."""
        stmt = select(MoodCheckin).where(
            MoodCheckin.user_id == user_id,
            MoodCheckin.client_id == client_id,
        )
        return self.db.scalars(stmt).first()

    def get_by_id(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
    ) -> Optional[MoodCheckin]:
        """Fetch checkin by checkin_id strictly scoped to user_id."""
        stmt = select(MoodCheckin).where(
            MoodCheckin.user_id == user_id,
            MoodCheckin.id == checkin_id,
        )
        return self.db.scalars(stmt).first()

    def list(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> Tuple[List[MoodCheckin], Optional[str], bool]:
        """
        List check-ins for user_id with cursor-based pagination and optional date filters.
        Ordered by local_date DESC, created_at DESC, id DESC.
        Returns: (items, next_cursor, has_more)
        """
        stmt = select(MoodCheckin).where(MoodCheckin.user_id == user_id)

        if from_date is not None:
            stmt = stmt.where(MoodCheckin.local_date >= from_date)
        if to_date is not None:
            stmt = stmt.where(MoodCheckin.local_date <= to_date)

        cursor_dict = decode_cursor(cursor)
        if cursor_dict and "local_date" in cursor_dict and "created_at" in cursor_dict and "id" in cursor_dict:
            try:
                cur_local_date = date.fromisoformat(cursor_dict["local_date"])
                cur_created_at = datetime.fromisoformat(cursor_dict["created_at"])
                cur_id = uuid.UUID(cursor_dict["id"])

                stmt = stmt.where(
                    or_(
                        MoodCheckin.local_date < cur_local_date,
                        and_(
                            MoodCheckin.local_date == cur_local_date,
                            MoodCheckin.created_at < cur_created_at,
                        ),
                        and_(
                            MoodCheckin.local_date == cur_local_date,
                            MoodCheckin.created_at == cur_created_at,
                            MoodCheckin.id < cur_id,
                        ),
                    )
                )
            except (ValueError, TypeError):
                pass

        stmt = stmt.order_by(
            MoodCheckin.local_date.desc(),
            MoodCheckin.created_at.desc(),
            MoodCheckin.id.desc(),
        ).limit(limit + 1)

        results = list(self.db.scalars(stmt).all())
        has_more = len(results) > limit
        items = results[:limit]

        next_cursor = None
        if has_more and items:
            last = items[-1]
            next_cursor = encode_cursor({
                "local_date": str(last.local_date),
                "created_at": last.created_at.isoformat(),
                "id": str(last.id),
            })

        return items, next_cursor, has_more

    def update(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
        updates: Dict[str, Any],
    ) -> Optional[MoodCheckin]:
        """Update check-in attributes strictly scoped to user_id."""
        checkin = self.get_by_id(user_id=user_id, checkin_id=checkin_id)
        if not checkin:
            return None

        immutable_fields = {"id", "user_id", "client_id", "created_at"}
        for key, value in updates.items():
            if hasattr(checkin, key) and key not in immutable_fields:
                setattr(checkin, key, value)

        self.db.commit()
        self.db.refresh(checkin)
        return checkin

    def delete(
        self,
        user_id: uuid.UUID,
        checkin_id: uuid.UUID,
    ) -> bool:
        """Delete check-in strictly scoped to user_id."""
        checkin = self.get_by_id(user_id=user_id, checkin_id=checkin_id)
        if not checkin:
            return False

        self.db.delete(checkin)
        self.db.commit()
        return True
