import uuid
from datetime import datetime
from typing import List, Literal, Optional
from zoneinfo import available_timezones
from pydantic import BaseModel, ConfigDict, Field, field_validator


class UserProfileResponse(BaseModel):
    """
    User profile model returned by GET /me.
    Strictly excludes password hashes, internal tokens, or sensitive health data.
    """

    id: uuid.UUID
    display_name: Optional[str] = None
    role: str
    created_at: datetime
    language: str
    timezone: str


class PreferencesUpdateRequest(BaseModel):
    """
    Payload for PATCH /me/preferences.
    Strictly whitelists non-consent user preferences and forbids unknown or consent fields.
    """

    model_config = ConfigDict(extra="forbid")

    timezone: Optional[str] = Field(None, description="IANA timezone identifier")
    language: Optional[Literal["en", "hi", "mr"]] = Field(
        None, description="App language (en, hi, mr)"
    )
    reminders_enabled: Optional[bool] = Field(None, description="Toggle general reminders")
    discreet_notifications: Optional[bool] = Field(
        None, description="Toggle discreet/neutral notifications"
    )

    @field_validator("timezone")
    @classmethod
    def validate_timezone(cls, v: Optional[str]) -> Optional[str]:
        if v is not None:
            tz = v.strip()
            if tz not in available_timezones():
                raise ValueError(
                    f"Invalid IANA timezone: '{tz}'. Must be a valid IANA timezone name."
                )
            return tz
        return v


class AccountDeleteRequest(BaseModel):
    """Payload for DELETE /me requiring explicit confirmation."""

    model_config = ConfigDict(extra="forbid")

    confirm: Literal["DELETE"] = Field(
        ...,
        description="Explicit uppercase string confirmation 'DELETE'",
    )


class PasswordChangeRequest(BaseModel):
    """Payload for POST /me/password."""

    model_config = ConfigDict(extra="forbid")

    current_password: str = Field(..., description="User's existing password")
    new_password: str = Field(..., min_length=10, description="New password meeting complexity rules")

    @field_validator("new_password")
    @classmethod
    def validate_new_password_strength(cls, v: str) -> str:
        from app.core.security import validate_password_strength
        validate_password_strength(v)
        return v


class SessionStatusResponse(BaseModel):
    """Minimal session status without device, IP, or location tracking."""

    model_config = ConfigDict(extra="forbid")
    active_sessions: int = Field(..., description="Count of active refresh token sessions")


class AccountEventResponse(BaseModel):
    """Minimal event audit item for security log."""

    model_config = ConfigDict(extra="forbid")

    id: uuid.UUID
    event_type: str
    created_at: datetime


class AccountEventListResponse(BaseModel):
    """Cursor-paginated security event log response."""

    model_config = ConfigDict(extra="forbid")

    items: List[AccountEventResponse]
    next_cursor: Optional[str] = None
    has_more: bool = False
