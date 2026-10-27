import uuid
from datetime import date
from enum import Enum
from typing import Optional
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    Index,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base, GUID, TimestampMixin


class EducationCategory(str, Enum):
    PERIODS_BASICS = "periods_basics"
    HYGIENE = "hygiene"
    COMMON_SYMPTOMS = "common_symptoms"
    WHEN_TO_SEEK_CARE = "when_to_seek_care"
    EMOTIONAL_WELLBEING = "emotional_wellbeing"
    SUPPORTING_SOMEONE = "supporting_someone"


class EducationLanguage(str, Enum):
    EN = "en"
    HI = "hi"
    MR = "mr"


class ReviewStatus(str, Enum):
    DRAFT = "draft"
    REVIEWED = "reviewed"


class EducationResource(Base, TimestampMixin):
    """Reviewed menstrual-health and self-care education content."""

    __tablename__ = "education_resources"
    __table_args__ = (
        UniqueConstraint("slug", "language", name="uq_education_slug_language"),
        Index("ix_education_category_language", "category", "language"),
        Index("ix_education_is_published", "is_published"),
        CheckConstraint(
            "category IN ('periods_basics', 'hygiene', 'common_symptoms', 'when_to_seek_care', 'emotional_wellbeing', 'supporting_someone')",
            name="ck_education_category",
        ),
        CheckConstraint(
            "language IN ('en', 'hi', 'mr')",
            name="ck_education_language",
        ),
        CheckConstraint(
            "review_status IN ('draft', 'reviewed')",
            name="ck_education_review_status",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    slug: Mapped[str] = mapped_column(
        String(100),
        nullable=False,
    )
    title: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
    )
    category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    language: Mapped[str] = mapped_column(
        String(10),
        default=EducationLanguage.EN.value,
        nullable=False,
    )
    summary: Mapped[str] = mapped_column(
        String(240),
        nullable=False,
    )
    body: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )
    source_name: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
    )
    source_url: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
    )
    review_status: Mapped[str] = mapped_column(
        String(20),
        default=ReviewStatus.DRAFT.value,
        nullable=False,
    )
    reviewed_at: Mapped[Optional[date]] = mapped_column(
        Date,
        nullable=True,
    )
    is_published: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
