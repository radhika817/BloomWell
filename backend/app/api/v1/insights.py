from datetime import date
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.insights import ExamContextInsightResponse, WeeklyInsightResponse
from app.services.insights_service import InsightsService

router = APIRouter(prefix="/insights", tags=["Insights"])


@router.get(
    "/weekly",
    response_model=WeeklyInsightResponse,
    status_code=status.HTTP_200_OK,
    summary="Get weekly personal wellness insights",
    description=(
        "Compares the target week's average scores (mood, stress, energy, sleep) with the "
        "user's previous 4 weeks. Requires at least 4 distinct check-in days in the week and "
        "at least 7 in the previous 4 weeks. Observation codes: HIGHER_THAN_USUAL, "
        "LOWER_THAN_USUAL, SIMILAR (threshold +/- 0.5 points)."
    ),
)
def get_weekly_insights(
    week_start: date = Query(..., description="Start date of the 7-day week (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WeeklyInsightResponse:
    service = InsightsService(db)
    return service.get_weekly_insights(current_user.id, week_start)


@router.get(
    "/exam-context",
    response_model=ExamContextInsightResponse,
    status_code=status.HTTP_200_OK,
    summary="Get exam context stress and energy insights",
    description=(
        "Compares average stress and energy in the 7 days before academic events in the last "
        "60 days with the baseline average outside those windows. Requires at least 2 events "
        "each with at least 3 check-in days. Codes: STRESS_HIGHER_BEFORE_EVENTS, etc. "
        "Output is strictly an observation, never a cause."
    ),
)
def get_exam_context_insights(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ExamContextInsightResponse:
    service = InsightsService(db)
    return service.get_exam_context_insights(current_user.id)
