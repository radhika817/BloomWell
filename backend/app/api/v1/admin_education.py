import uuid
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import require_role
from app.db.session import get_db
from app.models.user import User
from app.schemas.education import (
    CreateEducationRequest,
    EducationListResponse,
    EducationResponse,
    UpdateEducationRequest,
)
from app.services.education_service import EducationService

router = APIRouter(prefix="/admin/education", tags=["Admin Education"])


@router.get(
    "",
    response_model=EducationListResponse,
    summary="List Education Articles for Admin",
    description="Lists all educational content for administrative review.",
)
def list_admin_education(
    limit: int = Query(50, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> EducationListResponse:
    service = EducationService(db)
    return service.list_admin_education(limit=limit, cursor=cursor)


@router.post(
    "",
    response_model=EducationResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create Education Article",
    description="Creates a new educational content item.",
)
def create_education_article(
    req: CreateEducationRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> EducationResponse:
    service = EducationService(db)
    return service.create_education(req)


@router.patch(
    "/{id}",
    response_model=EducationResponse,
    summary="Update Education Article",
    description="Updates fields of an educational content item.",
)
def update_education_article(
    id: uuid.UUID,
    req: UpdateEducationRequest,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> EducationResponse:
    service = EducationService(db)
    return service.update_education(education_id=id, req=req)


@router.delete(
    "/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete Education Article",
    description="Deletes an educational content item.",
)
def delete_education_article(
    id: uuid.UUID,
    current_user: User = Depends(require_role("resource_admin")),
    db: Session = Depends(get_db),
) -> None:
    service = EducationService(db)
    service.delete_education(education_id=id)
