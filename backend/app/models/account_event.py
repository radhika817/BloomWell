import enum
import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import DateTime, Enum, ForeignKey, Index, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, GUID

if TYPE_CHECKING:
    from app.models.user import User


class AccountEventType(str, enum.Enum):
    EXPORT_REQUESTED = "export_requested"
    PASSWORD_CHANGED = "password_changed"
    SESSIONS_REVOKED = "sessions_revoked"
    CYCLE_DATA_DELETED = "cycle_data_deleted"
    CONSENT_CHANGED = "consent_changed"


class AccountEvent(Base):
    """
    User-visible security and privacy audit log.
    Minimal metadata only: event type and timestamp.
    No payloads, IP addresses, or device info.
    Cascades automatically on user deletion.
    """

    __tablename__ = "account_events"
    __table_args__ = (
        Index("ix_account_events_user_id_created_at", "user_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
    )
    event_type: Mapped[AccountEventType] = mapped_column(
        Enum(
            AccountEventType,
            name="account_event_type",
            values_callable=lambda obj: [e.value for e in obj],
        ),
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship(
        "User",
        back_populates="account_events",
    )
