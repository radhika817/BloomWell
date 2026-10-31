import re
from typing import Optional
from zoneinfo import available_timezones
from pydantic import BaseModel, Field, field_validator

from app.core.security import validate_password_strength
from app.schemas.user import UserProfileResponse

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")


class RegisterRequest(BaseModel):
    """User registration payload."""

    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=10, description="Plaintext password (min 10 chars)")
    display_name: Optional[str] = Field(None, max_length=100, description="Optional public display name")
    timezone: Optional[str] = Field("UTC", description="User IANA timezone (defaults to UTC)")

    @field_validator("email")
    @classmethod
    def validate_and_normalize_email(cls, v: str) -> str:
        trimmed = v.strip().lower()
        if not EMAIL_REGEX.match(trimmed):
            raise ValueError("Invalid email format.")
        return trimmed

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        validate_password_strength(v)
        return v

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, v: Optional[str]) -> str:
        tz = (v or "UTC").strip()
        if tz not in available_timezones():
            raise ValueError(f"Invalid IANA timezone: '{tz}'. Must be a valid IANA timezone name.")
        return tz


class LoginRequest(BaseModel):
    """User login payload."""

    email: str = Field(..., description="User email address")
    password: str = Field(..., description="User password")

    @field_validator("email")
    @classmethod
    def normalize_email(cls, v: str) -> str:
        return v.strip().lower()


class TokenResponse(BaseModel):
    """Token pair response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int = 900


class RefreshTokenRequest(BaseModel):
    """Refresh token rotation payload."""

    refresh_token: str = Field(..., description="Current opaque refresh token")


class AuthSuccessResponse(BaseModel):
    """Registration success payload containing tokens and minimal user profile."""

    tokens: TokenResponse
    user: UserProfileResponse


class ReauthRequest(BaseModel):
    """Step-up re-authentication payload."""

    password: str = Field(..., description="User password for step-up verification")


class ReauthResponse(BaseModel):
    """Step-up token response."""

    step_up_token: str
    token_type: str = "bearer"
    expires_in: int = 300
