"""Pydantic schemas for request and response validation."""
from app.schemas.auth import (
    AuthSuccessResponse,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
)
from app.schemas.checkin import (
    CheckinCreateRequest,
    CheckinListResponse,
    CheckinResponse,
    CheckinUpdateRequest,
)
from app.schemas.error import ErrorResponse
from app.schemas.health import HealthResponse
from app.schemas.journal import (
    JournalCreateRequest,
    JournalDetailResponse,
    JournalListResponse,
    JournalSummaryResponse,
    JournalUpdateRequest,
)
from app.schemas.user import PreferencesUpdateRequest, UserProfileResponse

__all__ = [
    "ErrorResponse",
    "HealthResponse",
    "RegisterRequest",
    "LoginRequest",
    "TokenResponse",
    "RefreshTokenRequest",
    "AuthSuccessResponse",
    "UserProfileResponse",
    "PreferencesUpdateRequest",
    "CheckinCreateRequest",
    "CheckinUpdateRequest",
    "CheckinResponse",
    "CheckinListResponse",
    "JournalCreateRequest",
    "JournalUpdateRequest",
    "JournalSummaryResponse",
    "JournalDetailResponse",
    "JournalListResponse",
]
