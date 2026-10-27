import uuid
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import CheckConstraint, DateTime, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin

if TYPE_CHECKING:
    from app.models.preference import UserPreference
    from app.models.token import RefreshToken
    from app.models.checkin import MoodCheckin
    from app.models.journal import JournalEntry
    from app.models.academic_event import AcademicEvent
    from app.models.cycle import CycleLog
    from app.models.activity import UserActivityLog
    from app.models.study_plan import StudyPlan
    from app.models.resource import ResourceReport


class User(Base, TimestampMixin):
    """User account model."""

    __tablename__ = "users"
    __table_args__ = (
        CheckConstraint(
            "role IN ('student', 'moderator', 'resource_admin')",
            name="ck_users_role",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    email: Mapped[str] = mapped_column(
        String(255),
        unique=True,
        index=True,
        nullable=False,
    )
    password_hash: Mapped[str] = mapped_column(
        String(255),
        nullable=False,
    )
    display_name: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
    )
    role: Mapped[str] = mapped_column(
        String(50),
        default="student",
        nullable=False,
    )
    deleted_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    # Relationships
    preferences: Mapped[Optional["UserPreference"]] = relationship(
        "UserPreference",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )
    refresh_tokens: Mapped[List["RefreshToken"]] = relationship(
        "RefreshToken",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    checkins: Mapped[List["MoodCheckin"]] = relationship(
        "MoodCheckin",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    journal_entries: Mapped[List["JournalEntry"]] = relationship(
        "JournalEntry",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    academic_events: Mapped[List["AcademicEvent"]] = relationship(
        "AcademicEvent",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    cycle_logs: Mapped[List["CycleLog"]] = relationship(
        "CycleLog",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    activity_logs: Mapped[List["UserActivityLog"]] = relationship(
        "UserActivityLog",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    study_plans: Mapped[List["StudyPlan"]] = relationship(
        "StudyPlan",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    resource_reports: Mapped[List["ResourceReport"]] = relationship(
        "ResourceReport",
        back_populates="reporter",
    )
