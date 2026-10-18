import uuid
from datetime import datetime
from typing import Literal, Optional
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
