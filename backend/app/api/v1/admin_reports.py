import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import require_role
from app.db.session import get_db
from app.models.user import User
from app.schemas.resource import (
    ResolveReportRequest,
    ResourceReportListResponse,
    ResourceReportResponse,
)
from app.services.resource_report_service import ResourceReportService

router = APIRouter(prefix="/admin/resource-reports", tags=["Admin Resource Reports"])


@router.get(
    "",
    response_model=ResourceReportListResponse,
    summary="List Resource Reports for Review",
    description="Returns reported resources with status filtering and cursor pagination. Reporter identity is strictly excluded.",
)
def list_admin_reports(
    status: Optional[str] = Query(None, description="Report status filter: open, resolved, dismissed"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceReportListResponse:
    service = ResourceReportService(db)
    return service.list_admin_reports(status=status, limit=limit, cursor=cursor)


@router.patch(
    "/{id}",
    response_model=ResourceReportResponse,
    summary="Resolve or Dismiss Resource Report",
    description="Updates report status to resolved or dismissed with optional resolution note.",
)
def update_report_status(
    id: uuid.UUID,
    req: ResolveReportRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceReportResponse:
    service = ResourceReportService(db)
    return service.update_report_status(
        report_id=id,
        new_status=req.status,
        resolved_note=req.resolved_note,
    )
