import uuid
from typing import TYPE_CHECKING, Optional
from sqlalchemy import ForeignKey, String, Text, UniqueConstraint, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class JournalEntry(Base, TimestampMixin):
    """Private student journal entry model."""

    __tablename__ = "journal_entries"
    __table_args__ = (
        UniqueConstraint("user_id", "client_id", name="uq_journal_entries_user_client"),
        Index("ix_journal_entries_user_id_created_at", "user_id", "created_at"),
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
    client_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        nullable=False,
    )
    title: Mapped[Optional[str]] = mapped_column(
        String(120),
        nullable=True,
    )
    body: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="journal_entries",
    )
