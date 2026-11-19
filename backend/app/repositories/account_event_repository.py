import uuid
from typing import List, Optional
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.account_event import AccountEvent, AccountEventType


class AccountEventRepository:
    """
    Data repository for AccountEvent records.
    Explicitly scoped by user_id.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def record_event(
        self,
        user_id: uuid.UUID,
        event_type: AccountEventType,
    ) -> AccountEvent:
        """Record an account event with minimal metadata only (no payload, IP, device)."""
        event = AccountEvent(
            user_id=user_id,
            event_type=event_type,
        )
        self.db.add(event)
        self.db.commit()
        self.db.refresh(event)
        return event

    def list_events(
        self,
        user_id: uuid.UUID,
        limit: int = 50,
        cursor: Optional[str] = None,
    ) -> List[AccountEvent]:
        """
        List account events for a user, newest first.
        Optional cursor is ISO timestamp or ID.
        """
        stmt = (
            select(AccountEvent)
            .where(AccountEvent.user_id == user_id)
            .order_by(AccountEvent.created_at.desc(), AccountEvent.id.desc())
        )
        if cursor:
            try:
                cursor_id = uuid.UUID(cursor)
                cursor_event = self.db.scalars(
                    select(AccountEvent).where(AccountEvent.id == cursor_id)
                ).first()
                if cursor_event:
                    stmt = stmt.where(
                        (AccountEvent.created_at < cursor_event.created_at)
                        | (
                            (AccountEvent.created_at == cursor_event.created_at)
                            & (AccountEvent.id < cursor_event.id)
                        )
                    )
            except ValueError:
                pass
        stmt = stmt.limit(limit)
        return list(self.db.scalars(stmt).all())
