import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import require_role
from app.db.session import get_db
from app.models.user import User
from app.schemas.resource import (
    CreateResourceRequest,
    ResourceListResponse,
    ResourceResponse,
    UpdateResourceRequest,
    VerifyResourceRequest,
)
from app.services.admin_resource_service import AdminResourceService

router = APIRouter(prefix="/admin/resources", tags=["Admin Resources"])


@router.get(
    "",
    response_model=ResourceListResponse,
    summary="List Resources for Admin Review",
    description="Lists resources for admin review, optionally filtering for stale listings needing verification.",
)
def list_admin_resources(
    stale: bool = Query(False, description="Filter for stale listings needing review"),
    limit: int = Query(50, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceListResponse:
    service = AdminResourceService(db)
    return service.list_resources(stale=stale, limit=limit, cursor=cursor)


@router.post(
    "",
    response_model=ResourceResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Resource Listing",
    description="Creates a new resource listing enforcing publishing integrity rules.",
)
def create_resource(
    req: CreateResourceRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceResponse:
    service = AdminResourceService(db)
    return service.create_resource(req)


@router.patch(
    "/{id}",
    response_model=ResourceResponse,
    summary="Update Resource Listing",
    description="Updates resource listing fields while re-validating publishing rules.",
)
def update_resource(
    id: uuid.UUID,
    req: UpdateResourceRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceResponse:
    service = AdminResourceService(db)
    return service.update_resource(resource_id=id, req=req)


@router.delete(
    "/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Resource Listing",
    description="Deletes a resource listing and its associated reports.",
)
def delete_resource(
    id: uuid.UUID,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> None:
    service = AdminResourceService(db)
    service.delete_resource(resource_id=id)


@router.post(
    "/{id}/verify",
    response_model=ResourceResponse,
    summary="Verify Resource Listing",
    description="Sets verification status to verified with official source_url and review date.",
)
def verify_resource(
    id: uuid.UUID,
    req: VerifyResourceRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceResponse:
    service = AdminResourceService(db)
    return service.verify_resource(resource_id=id, req=req)


@router.post(
    "/{id}/mark-outdated",
    response_model=ResourceResponse,
    summary="Mark Resource Outdated",
    description="Marks a resource status as outdated.",
)
def mark_resource_outdated(
    id: uuid.UUID,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> ResourceResponse:
    service = AdminResourceService(db)
    return service.mark_outdated(resource_id=id)
