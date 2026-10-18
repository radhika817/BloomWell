import uuid
from datetime import date, datetime
from typing import List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

MoodLabelType = Literal["happy", "calm", "okay", "sad", "stressed"]


class CheckinCreateRequest(BaseModel):
    """Payload for creating a mood check-in."""

    model_config = ConfigDict(extra="forbid")

    client_id: uuid.UUID = Field(..., description="Client-generated idempotency UUID")
    local_date: date = Field(..., description="User's local calendar date")
    mood_score: int = Field(..., ge=1, le=5, description="Mood score 1-5")
    stress_score: int = Field(..., ge=1, le=5, description="Stress score 1-5")
    energy_score: int = Field(..., ge=1, le=5, description="Energy score 1-5")
    sleep_quality_score: Optional[int] = Field(
        None, ge=1, le=5, description="Sleep quality score 1-5"
    )
    mood_label: Optional[MoodLabelType] = Field(
        None, description="Optional quick mood tag (happy, calm, okay, sad, stressed)"
    )
    tags: Optional[List[str]] = Field(
        None, max_length=5, description="Up to 5 descriptive tags, max 24 chars each"
    )
    notes: Optional[str] = Field(
        None, max_length=1000, description="Optional check-in notes up to 1000 characters"
    )

    @field_validator("tags")
    @classmethod
    def validate_tags(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            cleaned = []
            for tag in v:
                t = tag.strip()
                if len(t) > 24:
                    raise ValueError(f"Tag exceeds maximum length of 24 characters: '{t[:10]}...'")
                if t:
                    cleaned.append(t)
            if len(cleaned) > 5:
                raise ValueError("A maximum of 5 tags is allowed.")
            return cleaned
        return v

    @field_validator("notes")
    @classmethod
    def validate_notes(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            stripped = v.strip()
            return stripped if stripped else None
        return v


class CheckinUpdateRequest(BaseModel):
    """Payload for updating a mood check-in."""

    model_config = ConfigDict(extra="forbid")

    mood_score: Optional[int] = Field(None, ge=1, le=5, description="Mood score 1-5")
    stress_score: Optional[int] = Field(None, ge=1, le=5, description="Stress score 1-5")
    energy_score: Optional[int] = Field(None, ge=1, le=5, description="Energy score 1-5")
    sleep_quality_score: Optional[int] = Field(
        None, ge=1, le=5, description="Sleep quality score 1-5"
    )
    mood_label: Optional[MoodLabelType] = Field(
        None, description="Optional quick mood tag (happy, calm, okay, sad, stressed)"
    )
    tags: Optional[List[str]] = Field(
        None, max_length=5, description="Up to 5 descriptive tags, max 24 chars each"
    )
    notes: Optional[str] = Field(
        None, max_length=1000, description="Optional check-in notes up to 1000 characters"
    )

    @field_validator("tags")
    @classmethod
    def validate_tags(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        if v is not None:
            cleaned = []
            for tag in v:
                t = tag.strip()
                if len(t) > 24:
                    raise ValueError(f"Tag exceeds maximum length of 24 characters: '{t[:10]}...'")
                if t:
                    cleaned.append(t)
            if len(cleaned) > 5:
                raise ValueError("A maximum of 5 tags is allowed.")
            return cleaned
        return v

    @field_validator("notes")
    @classmethod
    def validate_notes(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            stripped = v.strip()
            return stripped if stripped else None
        return v


class CheckinResponse(BaseModel):
    """Complete representation of a mood check-in."""

    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    client_id: uuid.UUID
    local_date: date
    mood_score: int
    stress_score: int
    energy_score: int
    sleep_quality_score: Optional[int] = None
    mood_label: Optional[str] = None
    tags: Optional[List[str]] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class CheckinListResponse(BaseModel):
    """Cursor-paginated list of mood check-ins."""

    items: List[CheckinResponse]
    next_cursor: Optional[str] = None
    has_more: bool
