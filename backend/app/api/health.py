import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.schemas.health import HealthResponse

router = APIRouter(tags=["Health"])
logger = logging.getLogger(__name__)


@router.get(
    "/health",
    response_model=HealthResponse,
    status_code=status.HTTP_200_OK,
    summary="Health Check",
    description="Checks service and database availability without exposing sensitive details.",
)
def health_check(db: Session = Depends(get_db)) -> HealthResponse:
    """
    Perform a health check on the API and its primary database connection.
    Returns generic status indicators; never leaks connection strings, credentials, or hostnames.
    """
    try:
        db.execute(text("SELECT 1"))
        return HealthResponse(status="healthy", database="connected")
    except Exception as exc:
        logger.error("Database health check failed: %s", type(exc).__name__)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database connectivity unavailable.",
        )
