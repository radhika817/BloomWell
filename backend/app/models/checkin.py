import uuid
from datetime import date
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import Date, ForeignKey, Integer, String, Text, UniqueConstraint, Index, CheckConstraint
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy.types import TypeDecorator, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin

if TYPE_CHECKING:
    from app.models.user import User


class TextArray(TypeDecorator):
    """Platform-independent text array type.
    Uses PostgreSQL's ARRAY(String(24)), otherwise uses JSON.
    """

    impl = JSON
    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(PG_ARRAY(String(24)))
        return dialect.type_descriptor(JSON)

    def process_bind_param(self, value, dialect):
        if value is None:
            return None
        return list(value)

    def process_result_value(self, value, dialect):
        if value is None:
            return None
        return list(value)


class MoodCheckin(Base, TimestampMixin):
    """Daily mood and wellness check-in record."""

    __tablename__ = "mood_checkins"
    __table_args__ = (
        UniqueConstraint("user_id", "client_id", name="uq_mood_checkins_user_client"),
        Index("ix_mood_checkins_user_id_local_date", "user_id", "local_date"),
        Index("ix_mood_checkins_user_id_created_at", "user_id", "created_at"),
        CheckConstraint("mood_score >= 1 AND mood_score <= 5", name="ck_checkins_mood_score"),
        CheckConstraint("stress_score >= 1 AND stress_score <= 5", name="ck_checkins_stress_score"),
        CheckConstraint("energy_score >= 1 AND energy_score <= 5", name="ck_checkins_energy_score"),
        CheckConstraint(
            "sleep_quality_score IS NULL OR (sleep_quality_score >= 1 AND sleep_quality_score <= 5)",
            name="ck_checkins_sleep_score",
        ),
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
    local_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    mood_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    stress_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    energy_score: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    sleep_quality_score: Mapped[Optional[int]] = mapped_column(
        Integer,
        nullable=True,
    )
    mood_label: Mapped[Optional[str]] = mapped_column(
        String(20),
        nullable=True,
    )
    tags: Mapped[Optional[List[str]]] = mapped_column(
        TextArray(),
        nullable=True,
    )
    notes: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="checkins",
    )
