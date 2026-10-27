import uuid
from datetime import datetime
from typing import List, Optional, Tuple
from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import Session, selectinload

from app.core.pagination import decode_cursor, encode_cursor
from app.models.resource import ReportStatus, ResourceReport


class ReportExistsError(Exception):
    """Raised when an open report already exists for the given user and resource."""
    pass


class ResourceReportRepository:
    """
    Repository for user reports on outdated/broken resources.
    User operations are strictly owner-scoped by user_id.
    Admin operations provide a distinct query path.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def create_report(
        self,
        user_id: uuid.UUID,
        resource_id: uuid.UUID,
        reason: str,
        note: Optional[str] = None,
    ) -> ResourceReport:
        """
        Create a report strictly scoped to the reporting user.
        Rejects creation if an open report already exists for (user_id, resource_id).
        """
        existing_stmt = select(ResourceReport).where(
            ResourceReport.reporter_id == user_id,
            ResourceReport.resource_id == resource_id,
            ResourceReport.status == ReportStatus.OPEN.value,
        )
        if self.db.scalars(existing_stmt).first():
            raise ReportExistsError("An open report for this resource already exists.")

        report = ResourceReport(
            id=uuid.uuid4(),
            resource_id=resource_id,
            reporter_id=user_id,
            reason=reason,
            note=note,
            status=ReportStatus.OPEN.value,
        )
        self.db.add(report)
        self.db.commit()
        self.db.refresh(report)
        return report

    def get_user_reports(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[ResourceReport], Optional[str]]:
        """
        Retrieve reports submitted by the given user.
        Owner-scoped: strictly filters by reporter_id == user_id.
        """
        query = (
            select(ResourceReport)
            .options(selectinload(ResourceReport.resource))
            .where(ResourceReport.reporter_id == user_id)
        )

        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                query = query.where(
                    or_(
                        ResourceReport.created_at < c_created,
                        and_(ResourceReport.created_at == c_created, ResourceReport.id < c_id),
                    )
                )

        query = query.order_by(ResourceReport.created_at.desc(), ResourceReport.id.desc()).limit(limit + 1)
        items = list(self.db.scalars(query).all())

        next_cursor = None
        if len(items) > limit:
            items = items[:limit]
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    def count_daily_reports_for_user(
        self,
        user_id: uuid.UUID,
        since: datetime,
    ) -> int:
        """Count reports created by the user within the given time window for rate limiting."""
        stmt = (
            select(func.count(ResourceReport.id))
            .where(
                ResourceReport.reporter_id == user_id,
                ResourceReport.created_at >= since,
            )
        )
        return self.db.scalar(stmt) or 0

    # ------------------ Admin methods ------------------

    def get_by_id(self, report_id: uuid.UUID) -> Optional[ResourceReport]:
        """Fetch report by id with resource loaded."""
        stmt = (
            select(ResourceReport)
            .options(selectinload(ResourceReport.resource))
            .where(ResourceReport.id == report_id)
        )
        return self.db.scalars(stmt).first()

    def list_admin_reports(
        self,
        status: Optional[str] = None,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[ResourceReport], Optional[str]]:
        """
        List reports for administrative review.
        Eagerly loads resource but never exposes reporter identity.
        """
        query = select(ResourceReport).options(selectinload(ResourceReport.resource))

        if status:
            query = query.where(ResourceReport.status == status)

        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                query = query.where(
                    or_(
                        ResourceReport.created_at < c_created,
                        and_(ResourceReport.created_at == c_created, ResourceReport.id < c_id),
                    )
                )

        query = query.order_by(ResourceReport.created_at.desc(), ResourceReport.id.desc()).limit(limit + 1)
        items = list(self.db.scalars(query).all())

        next_cursor = None
        if len(items) > limit:
            items = items[:limit]
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    def update(self, report: ResourceReport) -> ResourceReport:
        """Update report status and resolution notes."""
        self.db.commit()
        self.db.refresh(report)
        return report
