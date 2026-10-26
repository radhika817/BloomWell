from datetime import date
from typing import Optional
import uuid
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.study_plan import (
    StudyPlanGenerateRequest,
    StudyPlanItemPatchRequest,
    StudyPlanItemResponse,
    StudyPlanResponse,
)
from app.services.planner_service import PlannerService

router = APIRouter(prefix="/study-plans", tags=["Study Planner"])


@router.post(
    "/generate",
    response_model=StudyPlanResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Generate 7-day study plan",
    description=(
        "Generates a 7-day study plan covering week_start. Returns 409 plan_exists if a plan "
        "already exists for that week unless replace is true. Suggests loads (light, normal, "
        "focus) and attaches study break activities."
    ),
)
def generate_study_plan(
    req: StudyPlanGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StudyPlanResponse:
    service = PlannerService(db)
    return service.generate_plan(
        user_id=current_user.id,
        week_start=req.week_start,
        replace=req.replace,
    )


@router.get(
    "/current",
    response_model=StudyPlanResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current week study plan",
    description="Returns the study plan covering today for the authenticated user, or 404.",
)
def get_current_study_plan(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StudyPlanResponse:
    service = PlannerService(db)
    return service.get_current_plan(user_id=current_user.id)


@router.get(
    "",
    response_model=StudyPlanResponse,
    status_code=status.HTTP_200_OK,
    summary="Get study plan by week_start",
    description="Returns the study plan for a specific week_start, or 404 if not found.",
)
def get_study_plan_by_query(
    week_start: date = Query(..., description="Start date of the week (YYYY-MM-DD)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StudyPlanResponse:
    service = PlannerService(db)
    return service.get_plan_by_week_or_id(user_id=current_user.id, week_start=week_start)


@router.get(
    "/{id}",
    response_model=StudyPlanResponse,
    status_code=status.HTTP_200_OK,
    summary="Get study plan by ID",
    description="Retrieves a study plan by ID strictly owned by the caller. Cross-user requests return 404.",
)
def get_study_plan_by_id(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StudyPlanResponse:
    service = PlannerService(db)
    return service.get_plan_by_week_or_id(user_id=current_user.id, plan_id=id)


@router.delete(
    "/{id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete study plan by ID",
    description="Permanently deletes a study plan owned by the caller. Cross-user requests return 404.",
)
def delete_study_plan(
    id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> None:
    service = PlannerService(db)
    service.delete_plan(user_id=current_user.id, plan_id=id)


@router.patch(
    "/items/{id}",
    response_model=StudyPlanItemResponse,
    status_code=status.HTTP_200_OK,
    summary="Update study plan item status or load",
    description=(
        "Updates item status (accepted, edited, skipped). suggested_load is allowed ONLY when "
        "status is edited. Any of light/normal/focus is allowed. Cross-user items return 404."
    ),
)
def patch_study_plan_item(
    id: uuid.UUID,
    req: StudyPlanItemPatchRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> StudyPlanItemResponse:
    service = PlannerService(db)
    return service.patch_item(user_id=current_user.id, item_id=id, req=req)
