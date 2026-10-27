import uuid
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.core.pagination import decode_cursor, encode_cursor
from app.models.education import EducationResource, ReviewStatus


class EducationRepository:
    """Repository for reviewed menstrual health and self-care education content."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_slug(
        self,
        slug: str,
        language: str = "en",
        allow_draft: bool = False,
    ) -> Optional[EducationResource]:
        """
        Fetch educational article by slug with language fallback to English.
        Respects publishing and draft visibility constraints.
        """
        query = select(EducationResource).where(
            EducationResource.slug == slug,
            EducationResource.is_published.is_(True),
        )
        if not allow_draft:
            query = query.where(EducationResource.review_status == ReviewStatus.REVIEWED.value)

        # First attempt requested language
        stmt_lang = query.where(EducationResource.language == language)
        res = self.db.scalars(stmt_lang).first()
        if res:
            return res

        # Fallback to English if not found and requested was not English
        if language != "en":
            stmt_en = query.where(EducationResource.language == "en")
            return self.db.scalars(stmt_en).first()

        return None

    def list_education(
        self,
        category: Optional[str] = None,
        language: str = "en",
        allow_draft: bool = False,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[EducationResource], Optional[str]]:
        """
        List educational articles with category filter and English fallback per slug.
        Only returns published items (and reviewed unless allow_draft is True).
        """
        query = select(EducationResource).where(EducationResource.is_published.is_(True))

        if not allow_draft:
            query = query.where(EducationResource.review_status == ReviewStatus.REVIEWED.value)

        if category:
            query = query.where(EducationResource.category == category)

        # Retrieve candidates in requested language or English for fallback
        target_languages = [language] if language == "en" else [language, "en"]
        query = query.where(EducationResource.language.in_(target_languages))
        query = query.order_by(EducationResource.created_at.desc(), EducationResource.id.desc())

        all_candidates = list(self.db.scalars(query).all())

        # Group by slug prioritizing requested language
        slug_map: Dict[str, EducationResource] = {}
        for item in all_candidates:
            if item.slug not in slug_map:
                slug_map[item.slug] = item
            elif item.language == language:
                slug_map[item.slug] = item

        # Deterministic sort
        sorted_items = sorted(
            slug_map.values(),
            key=lambda x: (x.created_at, x.id),
            reverse=True,
        )

        # Cursor pagination over deduplicated items
        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                sorted_items = [
                    item
                    for item in sorted_items
                    if (item.created_at < c_created)
                    or (item.created_at == c_created and item.id < c_id)
                ]

        items = sorted_items[:limit]
        next_cursor = None
        if len(sorted_items) > limit:
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    # ------------------ Admin methods ------------------

    def get_by_id(self, education_id: uuid.UUID) -> Optional[EducationResource]:
        """Fetch article by id."""
        stmt = select(EducationResource).where(EducationResource.id == education_id)
        return self.db.scalars(stmt).first()

    def list_admin_education(
        self,
        limit: int = 50,
        cursor: Optional[str] = None,
    ) -> Tuple[List[EducationResource], Optional[str]]:
        """List articles for administration."""
        query = select(EducationResource)

        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                query = query.where(
                    or_(
                        EducationResource.created_at < c_created,
                        and_(EducationResource.created_at == c_created, EducationResource.id < c_id),
                    )
                )

        query = query.order_by(EducationResource.created_at.desc(), EducationResource.id.desc()).limit(limit + 1)
        items = list(self.db.scalars(query).all())

        next_cursor = None
        if len(items) > limit:
            items = items[:limit]
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    def create(self, item: EducationResource) -> EducationResource:
        """Create and persist an educational article."""
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    def update(self, item: EducationResource) -> EducationResource:
        """Update and persist an educational article."""
        self.db.commit()
        self.db.refresh(item)
        return item

    def delete(self, item: EducationResource) -> None:
        """Delete an educational article."""
        self.db.delete(item)
        self.db.commit()
