import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.core.pagination import decode_cursor, encode_cursor
from app.models.journal import JournalEntry


class JournalRepository:
    """
    Owner-scoped repository for JournalEntry records.
    Every method requires an explicit user_id and filters strictly by it.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        user_id: uuid.UUID,
        client_id: uuid.UUID,
        title: Optional[str],
        body: str,
    ) -> JournalEntry:
        """Create a new journal entry strictly scoped to user_id."""
        entry = JournalEntry(
            id=uuid.uuid4(),
            user_id=user_id,
            client_id=client_id,
            title=title,
            body=body,
        )
        self.db.add(entry)
        self.db.commit()
        self.db.refresh(entry)
        return entry

    def get_by_client_id(
        self,
        user_id: uuid.UUID,
        client_id: uuid.UUID,
    ) -> Optional[JournalEntry]:
        """Fetch journal entry by client_id strictly scoped to user_id."""
        stmt = select(JournalEntry).where(
            JournalEntry.user_id == user_id,
            JournalEntry.client_id == client_id,
        )
        return self.db.scalars(stmt).first()

    def get_by_id(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
    ) -> Optional[JournalEntry]:
        """Fetch journal entry by id strictly scoped to user_id."""
        stmt = select(JournalEntry).where(
            JournalEntry.user_id == user_id,
            JournalEntry.id == journal_id,
        )
        return self.db.scalars(stmt).first()

    def list(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[JournalEntry], Optional[str], bool]:
        """
        List journal entries for user_id with cursor-based pagination.
        Ordered by created_at DESC, id DESC.
        Returns: (items, next_cursor, has_more)
        """
        stmt = select(JournalEntry).where(JournalEntry.user_id == user_id)

        cursor_dict = decode_cursor(cursor)
        if cursor_dict and "created_at" in cursor_dict and "id" in cursor_dict:
            try:
                cur_created_at = datetime.fromisoformat(cursor_dict["created_at"])
                cur_id = uuid.UUID(cursor_dict["id"])

                stmt = stmt.where(
                    or_(
                        JournalEntry.created_at < cur_created_at,
                        and_(
                            JournalEntry.created_at == cur_created_at,
                            JournalEntry.id < cur_id,
                        ),
                    )
                )
            except (ValueError, TypeError):
                pass

        stmt = stmt.order_by(
            JournalEntry.created_at.desc(),
            JournalEntry.id.desc(),
        ).limit(limit + 1)

        results = list(self.db.scalars(stmt).all())
        has_more = len(results) > limit
        items = results[:limit]

        next_cursor = None
        if has_more and items:
            last = items[-1]
            next_cursor = encode_cursor({
                "created_at": last.created_at.isoformat(),
                "id": str(last.id),
            })

        return items, next_cursor, has_more

    def update(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
        updates: Dict[str, Any],
    ) -> Optional[JournalEntry]:
        """Update journal entry attributes strictly scoped to user_id."""
        entry = self.get_by_id(user_id=user_id, journal_id=journal_id)
        if not entry:
            return None

        immutable_fields = {"id", "user_id", "client_id", "created_at"}
        for key, value in updates.items():
            if hasattr(entry, key) and key not in immutable_fields:
                setattr(entry, key, value)

        self.db.commit()
        self.db.refresh(entry)
        return entry

    def delete(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
    ) -> bool:
        """Delete journal entry strictly scoped to user_id."""
        entry = self.get_by_id(user_id=user_id, journal_id=journal_id)
        if not entry:
            return False

        self.db.delete(entry)
        self.db.commit()
        return True
