import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional
from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.token import RefreshToken


class RefreshTokenRepository:
    """
    Data repository for RefreshToken records.
    Manages hashed token creation, atomic rotation, and family-level revocation.
    """

    def __init__(self, db: Session) -> None:
        self.db = db

    def create(
        self,
        user_id: uuid.UUID,
        token_hash: str,
        family_id: Optional[uuid.UUID] = None,
        expires_at: Optional[datetime] = None,
    ) -> RefreshToken:
        """Create a new hashed refresh token."""
        now = datetime.now(timezone.utc)
        record = RefreshToken(
            id=uuid.uuid4(),
            user_id=user_id,
            token_hash=token_hash,
            family_id=family_id or uuid.uuid4(),
            expires_at=expires_at or (now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)),
            revoked_at=None,
            replaced_by=None,
        )
        self.db.add(record)
        self.db.commit()
        self.db.refresh(record)
        return record

    def get_by_token_hash(self, token_hash: str) -> Optional[RefreshToken]:
        """Look up refresh token record by its SHA-256 hash."""
        stmt = select(RefreshToken).where(RefreshToken.token_hash == token_hash)
        return self.db.scalars(stmt).first()

    def rotate(
        self,
        old_token: RefreshToken,
        new_token_hash: str,
    ) -> RefreshToken:
        """
        Atomically rotate refresh token:
        1. Mark old token as revoked and record replaced_by pointer.
        2. Create and insert new token under the same family_id.
        """
        now = datetime.now(timezone.utc)
        new_id = uuid.uuid4()

        new_token = RefreshToken(
            id=new_id,
            user_id=old_token.user_id,
            token_hash=new_token_hash,
            family_id=old_token.family_id,
            expires_at=now + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
            revoked_at=None,
            replaced_by=None,
        )

        old_token.revoked_at = now
        old_token.replaced_by = new_id

        self.db.add(new_token)
        self.db.commit()
        self.db.refresh(new_token)
        return new_token

    def revoke_family(self, family_id: uuid.UUID) -> None:
        """Revoke all tokens belonging to the specified family ID."""
        now = datetime.now(timezone.utc)
        stmt = (
            update(RefreshToken)
            .where(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
            .values(revoked_at=now)
        )
        self.db.execute(stmt)
        self.db.commit()
