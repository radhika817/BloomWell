from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.education import EducationListResponse, EducationResponse
from app.services.education_service import EducationService

router = APIRouter(prefix="/education", tags=["Reviewed Education"])


@router.get(
    "",
    response_model=EducationListResponse,
    summary="List Reviewed Menstrual Education Articles",
    description="Returns published educational articles with category filtering and English language fallback per slug.",
)
def list_education(
    category: Optional[str] = Query(None, description="Category filter"),
    language: str = Query("en", description="Language code (en, hi, mr) with English fallback"),
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> EducationListResponse:
    service = EducationService(db)
    return service.list_education(
        category=category,
        language=language,
        limit=limit,
        cursor=cursor,
    )


@router.get(
    "/{slug}",
    response_model=EducationResponse,
    summary="Get Education Article by Slug",
    description="Fetches an educational article by its slug, falling back to English if the requested language is unavailable.",
)
def get_education_article(
    slug: str,
    language: str = Query("en", description="Language code (en, hi, mr) with English fallback"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> EducationResponse:
    service = EducationService(db)
    return service.get_by_slug(slug=slug, language=language)
