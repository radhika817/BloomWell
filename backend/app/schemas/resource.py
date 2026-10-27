import re
import uuid
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.resource import CostType, ResourceCategory, VerificationStatus

PHONE_REGEX = re.compile(r"^(\+?[0-9\-\s\(\)]{7,30})$")


def compute_is_stale(
    last_verified_at: Optional[date],
    verification_status: str,
    stale_days: int = 180,
    reference_date: Optional[date] = None,
) -> bool:
    """
    Compute whether a resource listing is stale.
    A resource is stale if verification_status is outdated, last_verified_at is missing,
    or last_verified_at is >= stale_days old.
    """
    if verification_status == VerificationStatus.OUTDATED.value:
        return True
    if not last_verified_at:
        return True
    ref = reference_date or date.today()
    return (ref - last_verified_at) >= timedelta(days=stale_days)


class ResourceBase(BaseModel):
    name: str = Field(..., max_length=120)
    category: str
    description: str = Field(..., max_length=600)
    phone: Optional[str] = Field(None, max_length=30)
    email: Optional[str] = Field(None, max_length=255)
    website_url: Optional[str] = Field(None, max_length=500)
    address: Optional[str] = Field(None, max_length=200)
    city: Optional[str] = Field(None, max_length=100)
    hours_text: Optional[str] = Field(None, max_length=200)
    available_24x7: Optional[bool] = None
    languages: List[str] = Field(default_factory=list)
    cost: str = CostType.UNKNOWN.value
    product_details: Optional[Dict[str, Any]] = None
    source_url: Optional[str] = Field(None, max_length=500)
    verification_status: str = VerificationStatus.UNVERIFIED.value
    last_verified_at: Optional[date] = None
    verified_by: Optional[str] = Field(None, max_length=80)
    is_published: bool = False
    is_demo: bool = False

    model_config = ConfigDict(extra="forbid")

    @field_validator("category")
    @classmethod
    def validate_category(cls, v: str) -> str:
        valid = {c.value for c in ResourceCategory}
        if v not in valid:
            raise ValueError(f"Category must be one of: {sorted(valid)}")
        return v

    @field_validator("cost")
    @classmethod
    def validate_cost(cls, v: str) -> str:
        valid = {c.value for c in CostType}
        if v not in valid:
            raise ValueError(f"Cost must be one of: {sorted(valid)}")
        return v

    @field_validator("verification_status")
    @classmethod
    def validate_verification_status(cls, v: str) -> str:
        valid = {s.value for s in VerificationStatus}
        if v not in valid:
            raise ValueError(f"Verification status must be one of: {sorted(valid)}")
        return v

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            cleaned = v.strip()
            if not PHONE_REGEX.match(cleaned):
                raise ValueError("Invalid phone number format.")
            return cleaned
        return None

    @field_validator("email")
    @classmethod
    def validate_email(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            cleaned = v.strip()
            if "@" not in cleaned or "." not in cleaned.split("@")[-1]:
                raise ValueError("Invalid email address format.")
            return cleaned
        return None

    @field_validator("website_url", "source_url")
    @classmethod
    def validate_url(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and v.strip():
            cleaned = v.strip()
            if not (cleaned.startswith("http://") or cleaned.startswith("https://")):
                raise ValueError("URL must start with http:// or https://")
            return cleaned
        return None


class ResourceResponse(BaseModel):
    id: uuid.UUID
    name: str
    category: str
    description: str
    phone: Optional[str]
    email: Optional[str]
    website_url: Optional[str]
    address: Optional[str]
    city: Optional[str]
    hours_text: Optional[str]
    available_24x7: Optional[bool]
    languages: List[str]
    cost: str
    product_details: Optional[Dict[str, Any]]
    source_url: Optional[str]
    verification_status: str
    last_verified_at: Optional[date]
    verified_by: Optional[str]
    is_published: bool
    is_demo: bool
    is_stale: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(extra="forbid", from_attributes=True)


class ResourceListResponse(BaseModel):
    items: List[ResourceResponse]
    next_cursor: Optional[str] = None

    model_config = ConfigDict(extra="forbid")
