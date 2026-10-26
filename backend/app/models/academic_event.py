import uuid
from datetime import date
from typing import TYPE_CHECKING
from sqlalchemy import Date, ForeignKey, Index, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class AcademicEvent(Base, TimestampMixin):
    """Academic event model (e.g. exams, deadlines)."""

    __tablename__ = "academic_events"
    __table_args__ = (
        Index("ix_academic_events_user_id", "user_id"),
        Index("ix_academic_events_user_id_event_date", "user_id", "event_date"),
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
    title: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
    )
    event_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    event_type: Mapped[str] = mapped_column(
        String(50),
        default="exam",
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="academic_events",
    )
