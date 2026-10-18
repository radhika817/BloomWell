from typing import Any, Optional
from pydantic import BaseModel, Field


class ErrorResponse(BaseModel):
    """
    Standardized Problem-Details JSON error response.
    Guarantees consistent error shape across the entire API.
    """

    code: str = Field(..., description="Machine-readable error code")
    message: str = Field(..., description="Human-readable error description")
    details: Optional[Any] = Field(
        default=None,
        description="Detailed contextual error info or validation errors",
    )
    request_id: Optional[str] = Field(
        default=None,
        description="Unique correlation ID of the request",
    )
