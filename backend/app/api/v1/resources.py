import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.resource import ResourceListResponse, ResourceResponse
from app.services.resource_service import ResourceService

router = APIRouter(prefix="/resources", tags=["HelpHub Resources"])


@router.get(
    "/support",
    response_model=List[ResourceResponse],
    summary="Get Safety Layer Support Helplines and Counseling",
    description="Returns published, verified, non-stale helpline and counseling resources ordered with 24x7 first.",
)
def get_support_resources(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> List[ResourceResponse]:
    service = ResourceService(db)
    return service.get_support_resources()


@router.get(
    "",
    response_model=ResourceListResponse,
    summary="List HelpHub Resources",
    description="Returns published resources with optional category, city, language, and search filtering.",
)
def list_resources(
    category: Optional[str] = Query(None, description="Resource category filter"),
    city: Optional[str] = Query(None, description="City name filter"),
    language: Optional[str] = Query(None, description="Language code filter"),
    q: Optional[str] = Query(None, description="Search term for name and description"),
    free_only: bool = Query(False, description="Filter for free resources only"),
    include_outdated: bool = Query(False, description="Whether to include outdated resources"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ResourceListResponse:
    service = ResourceService(db)
    return service.list_resources(
        category=category,
        city=city,
        language=language,
        q=q,
        free_only=free_only,
        include_outdated=include_outdated,
        limit=limit,
        cursor=cursor,
    )


@router.get(
    "/{id}",
    response_model=ResourceResponse,
    summary="Get Resource by ID",
    description="Fetch details of a single published resource.",
)
def get_resource(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ResourceResponse:
    service = ResourceService(db)
    return service.get_resource(id)
