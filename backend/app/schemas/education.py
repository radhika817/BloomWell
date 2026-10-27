import re
import uuid
from datetime import date, datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.education import EducationCategory, EducationLanguage, ReviewStatus

HTML_TAG_REGEX = re.compile(r"<[^>]+>")


class EducationBase(BaseModel):
    slug: str = Field(..., max_length=100)
    title: str = Field(..., max_length=120)
    category: str
    language: str = Field(default=EducationLanguage.EN.value, max_length=10)
    summary: str = Field(..., max_length=240)
    body: str = Field(..., max_length=8000)
    source_name: str = Field(..., max_length=120)
    source_url: Optional[str] = Field(None, max_length=500)
    review_status: str = ReviewStatus.DRAFT.value
    reviewed_at: Optional[date] = None
    is_published: bool = False

    model_config = ConfigDict(extra="forbid")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        valid = {c.value for c in EducationCategory}
        if v not in valid:
            raise ValueError(f"Category must be one of: {sorted(valid)}")
        return v

    @field_validator("language")
    @classmethod
    def validate_language(cls, v: str) -> str:
        valid = {l.value for l in EducationLanguage}
        if v not in valid:
            raise ValueError(f"Language must be one of: {sorted(valid)}")
        return v

    @field_validator("review_status")
    @classmethod
    def validate_review_status(cls, v: str) -> str:
        valid = {s.value for s in ReviewStatus}
        if v not in valid:
            raise ValueError(f"Review status must be one of: {sorted(valid)}")
        return v

    @field_validator("body")
    @classmethod
    def validate_body_plain_text(cls, v: str) -> str:
        if HTML_TAG_REGEX.search(v):
            raise ValueError("Body must contain plain text paragraphs only, no HTML tags.")
        return v

    @field_validator("source_url")
    @classmethod
    def validate_source_url(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            cleaned = v.strip()
            if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
                raise ValueError("URL must start with http:// or https://")
            return cleaned
        return None


class CreateEducationRequest(EducationBase):
    """Admin request to create an education article."""
    pass


class UpdateEducationRequest(BaseModel):
    """Admin request to update an education article."""
    slug: Optional[str] = Field(None, max_length=100)
    title: Optional[str] = Field(None, max_length=120)
    category: Optional[str] = None
    language: Optional[str] = Field(None, max_length=10)
    summary: Optional[str] = Field(None, max_length=240)
    body: Optional[str] = Field(None, max_length=8000)
    source_name: Optional[str] = Field(None, max_length=120)
    source_url: Optional[str] = Field(None, max_length=500)
    review_status: Optional[str] = None
    reviewed_at: Optional[date] = None
    is_published: Optional[bool] = None

    model_config = ConfigDict(extra="forbid")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            valid = {c.value for c in EducationCategory}
            if v not in valid:
                raise ValueError(f"Category must be one of: {sorted(valid)}")
        return v

    @field_validator("language")
    @classmethod
    def validate_language(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            valid = {l.value for l in EducationLanguage}
            if v not in valid:
                raise ValueError(f"Language must be one of: {sorted(valid)}")
        return v

    @field_validator("review_status")
    @classmethod
    def validate_review_status(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            valid = {s.value for s in ReviewStatus}
            if v not in valid:
                raise ValueError(f"Review status must be one of: {sorted(valid)}")
        return v

    @field_validator("body")
    @classmethod
    def validate_body_plain_text(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and HTML_TAG_REGEX.search(v):
            raise ValueError("Body must contain plain text paragraphs only, no HTML tags.")
        return v

    @field_validator("source_url")
    @classmethod
    def validate_source_url(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            cleaned = v.strip()
            if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
                raise ValueError("URL must start with http:// or https://")
            return cleaned
        return None


class EducationResponse(BaseModel):
    id: uuid.UUID
    slug: str
    title: str
    category: str
    language: str
    summary: str
    body: str
    source_name: str
    source_url: Optional[str] = None
    review_status: str
    reviewed_at: Optional[date] = None
    is_published: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid", from_attributes=True)


class EducationListResponse(BaseModel):
    items: List[EducationResponse]
    next_cursor: Optional[str] = None

    model_config = ConfigDict(extra="forbid")
