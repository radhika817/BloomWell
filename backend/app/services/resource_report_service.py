import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.resource import ResourceReport
from app.repositories.resource_report_repository import (
    ReportExistsError,
    ResourceReportRepository,
)
from app.repositories.resource_repository import ResourceRepository
from app.schemas.resource import (
    CreateReportRequest,
    ResourceReportListResponse,
    ResourceReportResponse,
    ResourceResponse,
    compute_is_stale,
)


class ResourceReportService:
    """Service handling user reports for broken or outdated resources."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self.report_repo = ResourceReportRepository(db)
        self.resource_repo = ResourceRepository(db)

    def _to_response(self, report: ResourceReport) -> ResourceReportResponse:
        resource_resp = None
        if report.resource:
            res = report.resource
            stale = compute_is_stale(
                res.last_verified_at,
                res.verification_status,
                stale_days=settings.RESOURCE_STALE_DAYS,
            )
            resource_resp = ResourceResponse(
                id=res.id,
                name=res.name,
                category=res.category,
                description=res.description,
                phone=res.phone,
                email=res.email,
                website_url=res.website_url,
                address=res.address,
                city=res.city,
                hours_text=res.hours_text,
                available_24x7=res.available_24x7,
                languages=res.languages or [],
                cost=res.cost,
                product_details=res.product_details,
                source_url=res.source_url,
                verification_status=res.verification_status,
                last_verified_at=res.last_verified_at,
                verified_by=res.verified_by,
                is_published=res.is_published,
                is_demo=res.is_demo,
                is_stale=stale,
                created_at=res.created_at,
                updated_at=res.updated_at,
            )

        return ResourceReportResponse(
            id=report.id,
            resource_id=report.resource_id,
            reason=report.reason,
            note=report.note,
            status=report.status,
            created_at=report.created_at,
            resolved_at=report.resolved_at,
            resolved_note=report.resolved_note,
            resource=resource_resp,
        )

    def create_report(
        self,
        user_id: uuid.UUID,
        resource_id: uuid.UUID,
        req: CreateReportRequest,
    ) -> ResourceReportResponse:
        """Create a report on a resource with daily rate limiting (10/day)."""
        # Ensure resource exists and is published
        res = self.resource_repo.get_by_id(resource_id)
        if not res or not res.is_published:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )

        if not settings.ALLOW_DEMO_RESOURCES and res.is_demo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )

        # Rate limit: 10 reports per user per 24 hours
        since = datetime.now(timezone.utc) - timedelta(days=1)
        count = self.report_repo.count_daily_reports_for_user(user_id, since)
        if count >= 10:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Maximum 10 reports per day.",
            )

        try:
            report = self.report_repo.create_report(
                user_id=user_id,
                resource_id=resource_id,
                reason=req.reason,
                note=req.note,
            )
        except ReportExistsError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={"code": "report_exists", "message": "report_exists"},
            )

        return self._to_response(report)

    def get_my_reports(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> ResourceReportListResponse:
        """Retrieve caller's own reports strictly scoped to user_id."""
        items, next_cursor = self.report_repo.get_user_reports(
            user_id=user_id,
            limit=limit,
            cursor=cursor,
        )
        return ResourceReportListResponse(
            items=[self._to_response(item) for item in items],
            next_cursor=next_cursor,
        )
