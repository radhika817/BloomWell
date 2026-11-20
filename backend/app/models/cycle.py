import uuid
from datetime import date
from typing import TYPE_CHECKING, Optional
from sqlalchemy import Date, ForeignKey, Index, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class CycleLog(Base, TimestampMixin):
    """Menstrual cycle log model recording period start and end dates."""

    __tablename__ = "cycle_logs"
    __table_args__ = (
        Index("ix_cycle_logs_user_id_period_start", "user_id", "period_start"),
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
    period_start: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    period_end: Mapped[Optional[date]] = mapped_column(
        Date,
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="cycle_logs",
    )


class SymptomLog(Base, TimestampMixin):
    """Symptom log model recording daily logged symptoms and severity."""

    __tablename__ = "symptom_logs"
    __table_args__ = (
        Index("ix_symptom_logs_user_id_date", "user_id", "date"),
        Index("ix_symptom_logs_user_id_symptom_type", "user_id", "symptom_type"),
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
    client_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        nullable=True,
    )
    date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    symptom_type: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    custom_label: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
    )
    severity: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    notes: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="symptom_logs",
    )
