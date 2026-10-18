from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """
    Health check response model.
    Exposes service health and database connectivity status without sensitive details.
    """

    status: str = Field(..., description="Overall service status (e.g., 'healthy')")
    database: str = Field(..., description="Database connectivity status (e.g., 'connected')")
