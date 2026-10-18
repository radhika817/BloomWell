import re
import uuid
from typing import Any, Dict, List, Optional, Tuple
from sqlalchemy.orm import Session

from app.models.journal import JournalEntry
from app.repositories.journal_repository import JournalRepository


class JournalService:
    """
    Domain service for private student journal entries.
    Enforces privacy, owner scoping, client idempotency, and preview sanitization.
    """

    def __init__(self, db: Session) -> None:
        self.db = db
        self.journal_repo = JournalRepository(db)

    @staticmethod
    def generate_preview(body: str) -> str:
        """
        Generate a safe, collapsed preview (up to 80 characters) of the journal body.
        Collapses all newlines and multiple spaces into a single space.
        """
        if not body:
            return ""
        collapsed = re.sub(r"\s+", " ", body).strip()
        return collapsed[:80]

    def record_entry(
        self,
        user_id: uuid.UUID,
        client_id: uuid.UUID,
        title: Optional[str],
        body: str,
    ) -> Tuple[JournalEntry, bool]:
        """
        Record a private journal entry.
        Returns: (entry, created)
          - If client_id already exists for this user, returns (existing_entry, False) for idempotency (200 OK).
          - If newly created, returns (new_entry, True) (201 Created).
        """
        clean_title = title.strip() if title else None
        clean_body = body.strip()

        # Idempotency check: if client_id already recorded for this user, return existing record
        existing = self.journal_repo.get_by_client_id(user_id=user_id, client_id=client_id)
        if existing:
            return existing, False

        entry = self.journal_repo.create(
            user_id=user_id,
            client_id=client_id,
            title=clean_title,
            body=clean_body,
        )
        return entry, True

    def get_entry(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
    ) -> Optional[JournalEntry]:
        """Fetch full journal entry strictly scoped to user_id. Returns None if not found."""
        return self.journal_repo.get_by_id(user_id=user_id, journal_id=journal_id)

    def list_entries(
        self,
        user_id: uuid.UUID,
        limit: int = 20,
        cursor: Optional[str] = None,
    ) -> Tuple[List[Dict[str, Any]], Optional[str], bool]:
        """
        List journal entries for user_id with cursor pagination.
        Returns entries with previews (up to 80 chars) and strictly excludes full body.
        """
        limit = max(1, min(limit, 100))
        entries, next_cursor, has_more = self.journal_repo.list(
            user_id=user_id,
            limit=limit,
            cursor=cursor,
        )

        summaries = [
            {
                "id": entry.id,
                "client_id": entry.client_id,
                "title": entry.title,
                "preview": self.generate_preview(entry.body),
                "created_at": entry.created_at,
                "updated_at": entry.updated_at,
            }
            for entry in entries
        ]

        return summaries, next_cursor, has_more

    def update_entry(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
        updates: Dict[str, Any],
    ) -> Optional[JournalEntry]:
        """Update journal entry attributes strictly scoped to user_id."""
        clean_updates: Dict[str, Any] = {}
        if "title" in updates:
            t = updates["title"]
            clean_updates["title"] = t.strip() if t else None
        if "body" in updates:
            b = updates["body"]
            if b is not None:
                clean_updates["body"] = b.strip()

        return self.journal_repo.update(
            user_id=user_id,
            journal_id=journal_id,
            updates=clean_updates,
        )

    def delete_entry(
        self,
        user_id: uuid.UUID,
        journal_id: uuid.UUID,
    ) -> bool:
        """Delete journal entry strictly scoped to user_id."""
        return self.journal_repo.delete(user_id=user_id, journal_id=journal_id)
