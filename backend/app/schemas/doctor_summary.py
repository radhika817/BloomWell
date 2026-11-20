"""Doctor-visit summary request schema and validation rules."""

from datetime import date, datetime, timedelta
from typing import Optional
from zoneinfo import ZoneInfo
from fastapi import HTTPException, status
from pydantic import BaseModel, ConfigDict, Field, ValidationInfo, field_validator, model_validator


class UnsupportedLanguageError(HTTPException, ValueError):
    """Exception raised when an unsupported language is requested for the summary."""

    def __init__(
        self,
        message: str = "Only English ('en') is currently supported for doctor summary generation.",
    ):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={"code": "unsupported_language", "message": message},
        )
        self.code = "unsupported_language"
        self.message = message

    def __str__(self) -> str:
        return self.message


class DoctorSummaryInclude(BaseModel):
    """Category inclusion flags for doctor-visit summary."""

    model_config = ConfigDict(extra="forbid")

    periods: bool = Field(default=True, description="Include recorded periods")
    symptoms: bool = Field(default=True, description="Include logged symptoms")
    symptom_notes: bool = Field(
        default=False, description="Include user-written symptom notes"
    )
    estimate: bool = Field(
        default=False, description="Include next cycle window estimate"
    )
    questions: bool = Field(
        default=True, description="Include suggested questions for doctor"
    )

    @model_validator(mode="after")
    def validate_at_least_one_category(self) -> "DoctorSummaryInclude":
        if not self.periods and not self.symptoms:
            raise ValueError(
                "At least one of 'periods' or 'symptoms' must be included in the summary."
            )
        return self


class DoctorSummaryRequest(BaseModel):
    """Request payload for generating a doctor-visit summary PDF."""

    model_config = ConfigDict(extra="forbid")

    from_date: date = Field(
        ..., description="Start date of summary window (inclusive)"
    )
    to_date: date = Field(..., description="End date of summary window (inclusive)")
    include: DoctorSummaryInclude = Field(
        default_factory=DoctorSummaryInclude,
        description="Categories to include in the summary",
    )
    language: str = Field(
        default="en",
        description="Summary language code (only 'en' supported in v1)",
    )

    @field_validator("language")
    @classmethod
    def validate_language(cls, v: str) -> str:
        if v != "en":
            raise UnsupportedLanguageError(
                f"Unsupported language '{v}'. Only English ('en') is currently supported for doctor summary generation."
            )
        return v

    @model_validator(mode="after")
    def validate_request_bounds(self, info: ValidationInfo) -> "DoctorSummaryRequest":
        if self.from_date > self.to_date:
            raise ValueError("from_date cannot be after to_date.")

        from app.core.config import settings

        day_span = (self.to_date - self.from_date).days
        if day_span > settings.DOCTOR_SUMMARY_MAX_DAYS:
            raise ValueError(
                f"Requested date range of {day_span} days exceeds maximum allowed limit of {settings.DOCTOR_SUMMARY_MAX_DAYS} days."
            )

        tz_name = "UTC"
        if info.context and isinstance(info.context, dict):
            tz_name = info.context.get("timezone", "UTC") or "UTC"

        try:
            tz = ZoneInfo(tz_name)
        except Exception:
            tz = ZoneInfo("UTC")

        today_in_tz = datetime.now(tz).date()
        max_allowed_date = today_in_tz + timedelta(days=1)
        if self.to_date > max_allowed_date:
            raise ValueError(
                f"to_date '{self.to_date}' cannot be more than 1 day in the future (max allowed: {max_allowed_date} in timezone {tz_name})."
            )

        return self
