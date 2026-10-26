import enum
import uuid
from datetime import date, datetime, timezone
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID
from app.models.checkin import TextArray

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.academic_event import AcademicEvent
    from app.models.activity import Activity


class StudyPlanMode(str, enum.Enum):
    DEFAULT = "default"
    PERSONALIZED = "personalized"


class SuggestedLoad(str, enum.Enum):
    LIGHT = "light"
    NORMAL = "normal"
    FOCUS = "focus"


class PlanItemStatus(str, enum.Enum):
    SUGGESTED = "suggested"
    ACCEPTED = "accepted"
    EDITED = "edited"
    SKIPPED = "skipped"


class StudyPlan(Base):
    """Study plan entity for a 7-day academic week."""

    __tablename__ = "study_plans"
    __table_args__ = (
        UniqueConstraint("user_id", "week_start", name="uq_study_plans_user_week_start"),
        Index("ix_study_plans_user_id_week_start", "user_id", "week_start"),
        CheckConstraint("mode IN ('default', 'personalized')", name="ck_study_plans_mode"),
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
    week_start: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    days: Mapped[int] = mapped_column(
        Integer,
        default=7,
        nullable=False,
    )
    mode: Mapped[str] = mapped_column(
        String(20),
        default=StudyPlanMode.DEFAULT.value,
        nullable=False,
    )
    uses_cycle_data: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    checkin_days_used: Mapped[int] = mapped_column(
        Integer,
        default=0,
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="study_plans",
    )
    items: Mapped[List["StudyPlanItem"]] = relationship(
        "StudyPlanItem",
        back_populates="study_plan",
        cascade="all, delete-orphan",
        order_by="StudyPlanItem.plan_date",
    )


class StudyPlanItem(Base):
    """Daily study plan suggestion and user decision."""

    __tablename__ = "study_plan_items"
    __table_args__ = (
        UniqueConstraint("study_plan_id", "plan_date", name="uq_study_plan_items_plan_date"),
        Index("ix_study_plan_items_study_plan_id", "study_plan_id"),
        Index("ix_study_plan_items_plan_date", "plan_date"),
        CheckConstraint(
            "suggested_load IN ('light', 'normal', 'focus')",
            name="ck_study_plan_items_load",
        ),
        CheckConstraint(
            "status IN ('suggested', 'accepted', 'edited', 'skipped')",
            name="ck_study_plan_items_status",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    study_plan_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("study_plans.id", ondelete="CASCADE"),
        nullable=False,
    )
    plan_date: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )
    suggested_load: Mapped[str] = mapped_column(
        String(20),
        default=SuggestedLoad.NORMAL.value,
        nullable=False,
    )
    reason_codes: Mapped[List[str]] = mapped_column(
        TextArray(),
        nullable=False,
        default=list,
    )
    academic_event_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("academic_events.id", ondelete="SET NULL"),
        nullable=True,
    )
    activity_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("activities.id", ondelete="SET NULL"),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        default=PlanItemStatus.SUGGESTED.value,
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        onupdate=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    # Relationships
    study_plan: Mapped["StudyPlan"] = relationship(
        "StudyPlan",
        back_populates="items",
    )
    academic_event: Mapped[Optional["AcademicEvent"]] = relationship(
        "AcademicEvent",
    )
    activity: Mapped[Optional["Activity"]] = relationship(
        "Activity",
    )
