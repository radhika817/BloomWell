import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator


class JournalCreateRequest(BaseModel):
    """Payload for creating a private journal entry."""

    model_config = ConfigDict(extra="forbid")

    client_id: uuid.UUID = Field(..., description="Client-generated idempotency UUID")
    title: Optional[str] = Field(None, max_length=120, description="Optional title, max 120 characters")
    body: str = Field(..., min_length=1, max_length=10000, description="Journal body, 1-10000 characters")

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            stripped = v.strip()
            return stripped if stripped else None
        return v

    @field_validator("body")
    @classmethod
    def validate_body(cls, v: str) -> str:
        stripped = v.strip()
        if not stripped:
            raise ValueError("Journal entry body cannot be empty or whitespace only.")
        if len(stripped) > 10000:
            raise ValueError("Journal entry body exceeds maximum allowed length of 10,000 characters.")
        return stripped


class JournalUpdateRequest(BaseModel):
    """Payload for updating a private journal entry."""

    model_config = ConfigDict(extra="forbid")

    title: Optional[str] = Field(None, max_length=120, description="Optional title, max 120 characters")
    body: Optional[str] = Field(None, min_length=1, max_length=10000, description="Journal body, 1-10000 characters")

    @field_validator("title")
    @classmethod
    def validate_title(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            stripped = v.strip()
            return stripped if stripped else None
        return v

    @field_validator("body")
    @classmethod
    def validate_body(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            stripped = v.strip()
            if not stripped:
                raise ValueError("Journal entry body cannot be empty or whitespace only.")
            if len(stripped) > 10000:
                raise ValueError("Journal entry body exceeds maximum allowed length of 10,000 characters.")
            return stripped
        return v


class JournalSummaryResponse(BaseModel):
    """
    Summary view of a journal entry for list queries.
    Strictly provides a sanitized preview (<= 80 chars) and NEVER sends the full body over the wire.
    """

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    client_id: uuid.UUID
    title: Optional[str] = None
    preview: str
    created_at: datetime
    updated_at: datetime


class JournalDetailResponse(BaseModel):
    """
    Detailed view of a single journal entry including the full body.
    Strictly returned only for specific item retrieval (GET /v1/journal/{id}) or creation/update.
    """

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    client_id: uuid.UUID
    title: Optional[str] = None
    body: str
    created_at: datetime
    updated_at: datetime


class JournalListResponse(BaseModel):
    """Cursor-paginated list of journal entry summaries."""

    items: List[JournalSummaryResponse]
    next_cursor: Optional[str] = None
    has_more: bool
