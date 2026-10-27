import uuid
from datetime import date, datetime
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy import and_, cast, or_, select, String
from sqlalchemy.orm import Session

from app.core.pagination import decode_cursor, encode_cursor
from app.models.resource import Resource, VerificationStatus


class ResourceRepository:
    """Public catalog and admin repository for verified resources and period product access points."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_by_id(self, resource_id: uuid.UUID) -> Optional[Resource]:
        """Fetch a single resource by its primary key."""
        stmt = select(Resource).where(Resource.id == resource_id)
        return self.db.scalars(stmt).first()

    def list_resources(
        self,
        category: Optional[str] = None,
        city: Optional[str] = None,
        language: Optional[str] = None,
        q: Optional[str] = None,
        free_only: bool = False,
        include_outdated: bool = False,
        include_demo: bool = True,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[Resource], Optional[str]]:
        """List published resources with filters and cursor pagination."""
        query = select(Resource).where(Resource.is_published.is_(True))

        if not include_demo:
            query = query.where(Resource.is_demo.is_(False))

        if not include_outdated:
            query = query.where(Resource.verification_status != VerificationStatus.OUTDATED.value)

        if category:
            query = query.where(Resource.category == category)

        if city:
            query = query.where(Resource.city.ilike(f"%{city}%"))

        if free_only:
            query = query.where(Resource.cost == "free")

        if language:
            # Match language inside JSON/array representation
            query = query.where(cast(Resource.languages, String).ilike(f'%"{language}"%'))

        if q:
            search_pattern = f"%{q.strip()}%"
            query = query.where(
                or_(
                    Resource.name.ilike(search_pattern),
                    Resource.description.ilike(search_pattern),
                )
            )

        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                query = query.where(
                    or_(
                        Resource.created_at < c_created,
                        and_(Resource.created_at == c_created, Resource.id < c_id),
                    )
                )

        query = query.order_by(Resource.created_at.desc(), Resource.id.desc()).limit(limit + 1)
        items = list(self.db.scalars(query).all())

        next_cursor = None
        if len(items) > limit:
            items = items[:limit]
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    def get_support_resources(
        self,
        stale_threshold_date: date,
        include_demo: bool = True,
    ) -> List[Resource]:
        """
        Fetch published, verified, non-stale helpline and counseling resources only.
        Ordered deterministically: 24x7 verified first, then name ascending.
        Used by the Safety Layer.
        """
        query = (
            select(Resource)
            .where(
                Resource.is_published.is_(True),
                Resource.verification_status == VerificationStatus.VERIFIED.value,
                Resource.category.in_(["helpline", "counseling"]),
                Resource.last_verified_at.is_not(None),
                Resource.last_verified_at >= stale_threshold_date,
            )
        )

        if not include_demo:
            query = query.where(Resource.is_demo.is_(False))

        # 24x7 first, then name
        query = query.order_by(
            Resource.available_24x7.desc().nullslast(),
            Resource.name.asc(),
            Resource.id.asc(),
        )
        return list(self.db.scalars(query).all())

    def list_admin_resources(
        self,
        stale_before_date: Optional[date] = None,
        limit: int = 50,
        cursor: Optional[str] = None,
    ) -> Tuple[List[Resource], Optional[str]]:
        """Admin resource listing, optionally filtered for stale resources."""
        query = select(Resource)

        if stale_before_date:
            query = query.where(
                or_(
                    Resource.last_verified_at.is_(None),
                    Resource.last_verified_at < stale_before_date,
                    Resource.verification_status == VerificationStatus.OUTDATED.value,
                )
            )

        if cursor:
            decoded = decode_cursor(cursor)
            if decoded and "created_at" in decoded and "id" in decoded:
                c_created = datetime.fromisoformat(decoded["created_at"])
                c_id = uuid.UUID(decoded["id"])
                query = query.where(
                    or_(
                        Resource.created_at < c_created,
                        and_(Resource.created_at == c_created, Resource.id < c_id),
                    )
                )

        query = query.order_by(Resource.created_at.desc(), Resource.id.desc()).limit(limit + 1)
        items = list(self.db.scalars(query).all())

        next_cursor = None
        if len(items) > limit:
            items = items[:limit]
            last_item = items[-1]
            next_cursor = encode_cursor(
                {"created_at": last_item.created_at.isoformat(), "id": str(last_item.id)}
            )

        return items, next_cursor

    def create(self, resource: Resource) -> Resource:
        """Create and persist a new resource."""
        self.db.add(resource)
        self.db.commit()
        self.db.refresh(resource)
        return resource

    def update(self, resource: Resource) -> Resource:
        """Update and persist an existing resource."""
        self.db.commit()
        self.db.refresh(resource)
        return resource

    def delete(self, resource: Resource) -> None:
        """Delete a resource."""
        self.db.delete(resource)
        self.db.commit()
