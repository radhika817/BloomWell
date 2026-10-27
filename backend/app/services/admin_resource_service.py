import uuid
from datetime import date, timedelta
from typing import Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.resource import Resource, VerificationStatus
from app.repositories.resource_repository import ResourceRepository
from app.schemas.resource import (
    CreateResourceRequest,
    ResourceListResponse,
    ResourceResponse,
    UpdateResourceRequest,
    VerifyResourceRequest,
    compute_is_stale,
)


class AdminResourceService:
    """Service handling resource administration and verification workflows."""

    def __init__(self, db: Session) -> None:
        self.db = db
        self.repo = ResourceRepository(db)

    def _validate_integrity_rules(
        self,
        is_published: bool,
        is_demo: bool,
        verification_status: str,
        source_url: Optional[str],
        last_verified_at: Optional[date],
        available_24x7: Optional[bool],
    ) -> None:
        """Enforce domain rules for published listings and 24x7 claims."""
        if is_published and not is_demo:
            if (
                verification_status != VerificationStatus.VERIFIED.value
                or not source_url
                or not last_verified_at
            ):
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="A published non-demo resource must have verification_status='verified', source_url, and last_verified_at.",
                )

        if available_24x7 is True:
            if verification_status != VerificationStatus.VERIFIED.value or not source_url:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="available_24x7 may be true only when verified with a source_url.",
                )

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

    def create_resource(self, req: CreateResourceRequest) -> ResourceResponse:
        """Create a new resource listing after validating domain rules."""
        self._validate_integrity_rules(
            is_published=req.is_published,
            is_demo=req.is_demo,
            verification_status=req.verification_status,
            source_url=req.source_url,
            last_verified_at=req.last_verified_at,
            available_24x7=req.available_24x7,
        )
        res = Resource(
            id=uuid.uuid4(),
            name=req.name,
            category=req.category,
            description=req.description,
            phone=req.phone,
            email=req.email,
            website_url=req.website_url,
            address=req.address,
            city=req.city,
            hours_text=req.hours_text,
            available_24x7=req.available_24x7,
            languages=req.languages,
            cost=req.cost,
            product_details=req.product_details,
            source_url=req.source_url,
            verification_status=req.verification_status,
            last_verified_at=req.last_verified_at,
            verified_by=req.verified_by,
            is_published=req.is_published,
            is_demo=req.is_demo,
        )
        created = self.repo.create(res)
        return self._to_response(created)

    def update_resource(self, resource_id: uuid.UUID, req: UpdateResourceRequest) -> ResourceResponse:
        """Update an existing resource listing."""
        res = self.repo.get_by_id(resource_id)
        if not res:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )

        updates = req.model_dump(exclude_unset=True)
        new_is_published = updates.get("is_published", res.is_published)
        new_is_demo = updates.get("is_demo", res.is_demo)
        new_ver_status = updates.get("verification_status", res.verification_status)
        new_source_url = updates.get("source_url", res.source_url)
        new_last_verified_at = updates.get("last_verified_at", res.last_verified_at)
        new_available_24x7 = updates.get("available_24x7", res.available_24x7)

        self._validate_integrity_rules(
            is_published=new_is_published,
            is_demo=new_is_demo,
            verification_status=new_ver_status,
            source_url=new_source_url,
            last_verified_at=new_last_verified_at,
            available_24x7=new_available_24x7,
        )

        for field, value in updates.items():
            setattr(res, field, value)

        updated = self.repo.update(res)
        return self._to_response(updated)

    def delete_resource(self, resource_id: uuid.UUID) -> None:
        """Delete a resource listing."""
        res = self.repo.get_by_id(resource_id)
        if not res:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )
        self.repo.delete(res)

    def verify_resource(self, resource_id: uuid.UUID, req: VerifyResourceRequest) -> ResourceResponse:
        """Set verification details and mark status as verified."""
        res = self.repo.get_by_id(resource_id)
        if not res:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )

        res.verification_status = VerificationStatus.VERIFIED.value
        res.source_url = req.source_url
        res.last_verified_at = req.last_verified_at
        res.verified_by = req.verified_by

        updated = self.repo.update(res)
        return self._to_response(updated)

    def mark_outdated(self, resource_id: uuid.UUID) -> ResourceResponse:
        """Mark a resource listing as outdated."""
        res = self.repo.get_by_id(resource_id)
        if not res:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Resource not found.",
            )

        res.verification_status = VerificationStatus.OUTDATED.value
        updated = self.repo.update(res)
        return self._to_response(updated)

    def list_resources(
        self,
        stale: bool = False,
        limit: int = 50,
        cursor: Optional[str] = None,
    ) -> ResourceListResponse:
        """List resources for administration, optionally filtering for stale listings."""
        stale_threshold = None
        if stale:
            stale_threshold = date.today() - timedelta(days=settings.RESOURCE_STALE_DAYS)

        items, next_cursor = self.repo.list_admin_resources(
            stale_before_date=stale_threshold,
            limit=limit,
            cursor=cursor,
        )
        return ResourceListResponse(
            items=[self._to_response(item) for item in items],
            next_cursor=next_cursor,
        )
