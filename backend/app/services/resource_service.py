import uuid
from datetime import date, timedelta
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.resource import Resource
from app.repositories.resource_repository import ResourceRepository
from app.schemas.resource import (
    ResourceListResponse,
    ResourceResponse,
    compute_is_stale,
)


class ResourceService:
    """Service handling public catalog and support resource queries."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ResourceRepository(db)

    def _to_response(self, resource: Resource) -> ResourceResponse:
        stale = compute_is_stale(
            resource.last_verified_at,
            resource.verification_status,
            stale_days=settings.RESOURCE_STALE_DAYS,
        )
        return ResourceResponse(
            id=resource.id,
            name=resource.name,
            category=resource.category,
            description=resource.description,
            phone=resource.phone,
            email=resource.email,
            website_url=resource.website_url,
            address=resource.address,
            city=resource.city,
            hours_text=resource.hours_text,
            available_24x7=resource.available_24x7,
            languages=resource.languages or [],
            cost=resource.cost,
            product_details=resource.product_details,
            source_url=resource.source_url,
            verification_status=resource.verification_status,
            last_verified_at=resource.last_verified_at,
            verified_by=resource.verified_by,
            is_published=resource.is_published,
            is_demo=resource.is_demo,
            is_stale=stale,
            created_at=resource.created_at,
            updated_at=resource.updated_at,
        )

    def get_resource(self, resource_id: uuid.UUID) -> ResourceResponse:
        """Retrieve a published resource by ID."""
        res = self.repo.get_by_id(resource_id)
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

        return self._to_response(res)

    def list_resources(
        self,
        category: Optional[str] = None,
        city: Optional[str] = None,
        language: Optional[str] = None,
        q: Optional[str] = None,
        free_only: bool = False,
        include_outdated: bool = False,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> ResourceListResponse:
        """List published resources with filtering and cursor pagination."""
        items, next_cursor = self.repo.list_resources(
            category=category,
            city=city,
            language=language,
            q=q,
            free_only=free_only,
            include_outdated=include_outdated,
            include_demo=settings.ALLOW_DEMO_RESOURCES,
            limit=limit,
            cursor=cursor,
        )
        return ResourceListResponse(
            items=[self._to_response(item) for item in items],
            next_cursor=next_cursor,
        )

    def get_support_resources(self) -> List[ResourceResponse]:
        """
        Retrieve verified, non-stale counseling and helpline resources.
        Used by the Safety Layer.
        """
        stale_threshold = date.today() - timedelta(days=settings.RESOURCE_STALE_DAYS)
        items = self.repo.get_support_resources(
            stale_threshold_date=stale_threshold,
            include_demo=settings.ALLOW_DEMO_RESOURCES,
        )
        return [self._to_response(item) for item in items]
