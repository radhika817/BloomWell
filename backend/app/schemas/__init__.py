"""Pydantic schemas for request and response validation."""
from app.schemas.auth import (
    AuthSuccessResponse,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
)
from app.schemas.error import ErrorResponse
from app.schemas.health import HealthResponse
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
]
