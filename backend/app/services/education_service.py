from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.repositories.education_repository import EducationRepository
from app.schemas.education import EducationListResponse, EducationResponse


class EducationService:
    """Service handling public educational content requests with English fallback."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = EducationRepository(db)

    def get_by_slug(self, slug: str, language: str = "en") -> EducationResponse:
        """Fetch article by slug with language fallback and draft gating."""
        article = self.repo.get_by_slug(
            slug=slug,
            language=language,
            allow_draft=settings.ALLOW_DRAFT_CONTENT,
        )
        if not article:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Education article not found.",
            )
        return EducationResponse.model_validate(article)

    def list_education(
        self,
        category: Optional[str] = None,
        language: str = "en",
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> EducationListResponse:
        """List published articles with language fallback to English and draft gating."""
        items, next_cursor = self.repo.list_education(
            category=category,
            language=language,
            allow_draft=settings.ALLOW_DRAFT_CONTENT,
            limit=limit,
            cursor=cursor,
        )
        return EducationListResponse(
            items=[EducationResponse.model_validate(it) for it in items],
            next_cursor=next_cursor,
        )
