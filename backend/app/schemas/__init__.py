"""Pydantic schemas for request and response validation."""
from app.schemas.error import ErrorResponse
from app.schemas.health import HealthResponse

__all__ = ["ErrorResponse", "HealthResponse"]
