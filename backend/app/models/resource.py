import uuid
from datetime import date, datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional
from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    JSON,
    String,
    func,
    text,
)
from sqlalchemy.dialects import postgresql
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base, GUID, TimestampMixin


class ResourceCategory(str, Enum):
    COUNSELING = "counseling"
    HELPLINE = "helpline"
    WELFARE_OFFICE = "welfare_office"
    PERIOD_PRODUCTS = "period_products"
    NGO = "ngo"
    HEALTH_CLINIC = "health_clinic"
    WORKSHOP = "workshop"


class CostType(str, Enum):
    FREE = "free"
    PAID = "paid"
    UNKNOWN = "unknown"


class VerificationStatus(str, Enum):
    UNVERIFIED = "unverified"
    VERIFIED = "verified"
    OUTDATED = "outdated"


class ReportReason(str, Enum):
    OUTDATED = "outdated"
    OUT_OF_ORDER = "out_of_order"
    INCORRECT = "incorrect"
    CLOSED = "closed"
    OTHER = "other"


class ReportStatus(str, Enum):
    OPEN = "open"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class Resource(Base, TimestampMixin):
    """Verified Support and Period Product Resource catalog entry."""

    __tablename__ = "resources"
    __table_args__ = (
        Index("ix_resources_category_city", "category", "city"),
        Index("ix_resources_is_published", "is_published"),
        CheckConstraint(
            "category IN ('counseling', 'helpline', 'welfare_office', 'period_products', 'ngo', 'health_clinic', 'workshop')",
            name="ck_resources_category",
        ),
        CheckConstraint(
            "cost IN ('free', 'paid', 'unknown')",
            name="ck_resources_cost",
        ),
        CheckConstraint(
            "verification_status IN ('unverified', 'verified', 'outdated')",
            name="ck_resources_verification_status",
        ),
        CheckConstraint(
            "NOT (is_published = true AND is_demo = false) OR (verification_status = 'verified' AND source_url IS NOT NULL AND last_verified_at IS NOT NULL)",
            name="ck_resources_published_verified",
        ),
        CheckConstraint(
            "available_24x7 IS NOT TRUE OR (verification_status = 'verified' AND source_url IS NOT NULL)",
            name="ck_resources_24x7_verified",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    name: Mapped[str] = mapped_column(
        String(120),
        nullable=False,
    )
    category: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    description: Mapped[str] = mapped_column(
        String(600),
        nullable=False,
    )
    phone: Mapped[Optional[str]] = mapped_column(
        String(30),
        nullable=True,
    )
    email: Mapped[Optional[str]] = mapped_column(
        String(255),
        nullable=True,
    )
    website_url: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
    )
    address: Mapped[Optional[str]] = mapped_column(
        String(200),
        nullable=True,
    )
    city: Mapped[Optional[str]] = mapped_column(
        String(100),
        nullable=True,
    )
    hours_text: Mapped[Optional[str]] = mapped_column(
        String(200),
        nullable=True,
    )
    available_24x7: Mapped[Optional[bool]] = mapped_column(
        Boolean,
        nullable=True,
        default=None,
    )
    languages: Mapped[List[str]] = mapped_column(
        postgresql.ARRAY(String(20)).with_variant(JSON(), "sqlite"),
        nullable=False,
        default=list,
    )
    cost: Mapped[str] = mapped_column(
        String(20),
        default=CostType.UNKNOWN.value,
        nullable=False,
    )
    product_details: Mapped[Optional[Dict[str, Any]]] = mapped_column(
        postgresql.JSONB().with_variant(JSON(), "sqlite"),
        nullable=True,
    )
    source_url: Mapped[Optional[str]] = mapped_column(
        String(500),
        nullable=True,
    )
    verification_status: Mapped[str] = mapped_column(
        String(20),
        default=VerificationStatus.UNVERIFIED.value,
        nullable=False,
    )
    last_verified_at: Mapped[Optional[date]] = mapped_column(
        Date,
        nullable=True,
    )
    verified_by: Mapped[Optional[str]] = mapped_column(
        String(80),
        nullable=True,
    )
    is_published: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )
    is_demo: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    # Relationships
    reports: Mapped[List["ResourceReport"]] = relationship(
        "ResourceReport",
        back_populates="resource",
        cascade="all, delete-orphan",
    )


class ResourceReport(Base):
    """User report on outdated or broken resource entries."""

    __tablename__ = "resource_reports"
    __table_args__ = (
        Index(
            "uq_resource_reports_open",
            "reporter_id",
            "resource_id",
            unique=True,
            postgresql_where=text("status = 'open'"),
            sqlite_where=text("status = 'open'"),
        ),
        CheckConstraint(
            "reason IN ('outdated', 'out_of_order', 'incorrect', 'closed', 'other')",
            name="ck_resource_reports_reason",
        ),
        CheckConstraint(
            "status IN ('open', 'resolved', 'dismissed')",
            name="ck_resource_reports_status",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        primary_key=True,
        default=uuid.uuid4,
    )
    resource_id: Mapped[uuid.UUID] = mapped_column(
        GUID(),
        ForeignKey("resources.id", ondelete="CASCADE"),
        nullable=False,
    )
    reporter_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        GUID(),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    reason: Mapped[str] = mapped_column(
        String(50),
        nullable=False,
    )
    note: Mapped[Optional[str]] = mapped_column(
        String(300),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        default=ReportStatus.OPEN.value,
        nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        server_default=func.now(),
        nullable=False,
    )
    resolved_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    resolved_note: Mapped[Optional[str]] = mapped_column(
        String(300),
        nullable=True,
    )

    # Relationships
    resource: Mapped["Resource"] = relationship(
        "Resource",
        back_populates="reports",
    )
    reporter: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[reporter_id],
        back_populates="resource_reports",
    )


# Late imports for typing
from app.models.user import User  # noqa: E402
