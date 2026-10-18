import uuid
from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.checkin import (
    CheckinCreateRequest,
    CheckinListResponse,
    CheckinResponse,
    CheckinUpdateRequest,
)
from app.services.wellness_service import WellnessService

router = APIRouter(prefix="/checkins", tags=["Checkins"])


@router.post(
    "",
    response_model=CheckinResponse,
    summary="Record a mood check-in",
    description="Records a student mood and wellness check-in. Idempotent on client_id (returns 200 OK on replay, 201 Created on initial creation).",
)
def create_checkin(
    req: CheckinCreateRequest,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckinResponse:
    wellness_service = WellnessService(db)
    try:
        checkin, created = wellness_service.record_checkin(
            user_id=current_user.id,
            client_id=req.client_id,
            local_date=req.local_date,
            mood_score=req.mood_score,
            stress_score=req.stress_score,
            energy_score=req.energy_score,
            sleep_quality_score=req.sleep_quality_score,
            mood_label=req.mood_label,
            tags=req.tags,
            notes=req.notes,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    response.status_code = status.HTTP_201_CREATED if created else status.HTTP_200_OK
    return checkin


@router.get(
    "",
    response_model=CheckinListResponse,
    status_code=status.HTTP_200_OK,
    summary="List mood check-ins",
    description="Returns cursor-paginated check-in history strictly for the authenticated user, optionally filtered by local_date.",
)
def list_checkins(
    limit: int = Query(default=20, ge=1, le=100, description="Items per page (1-100)"),
    cursor: Optional[str] = Query(default=None, description="Cursor for pagination"),
    from_date: Optional[date] = Query(default=None, description="Earliest local_date (inclusive)"),
    to_date: Optional[date] = Query(default=None, description="Latest local_date (inclusive)"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckinListResponse:
    wellness_service = WellnessService(db)
    try:
        items, next_cursor, has_more = wellness_service.list_checkins(
            user_id=current_user.id,
            limit=limit,
            cursor=cursor,
            from_date=from_date,
            to_date=to_date,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(e),
        )

    return CheckinListResponse(
        items=[CheckinResponse.model_validate(item) for item in items],
        next_cursor=next_cursor,
        has_more=has_more,
    )


@router.get(
    "/{checkin_id}",
    response_model=CheckinResponse,
    status_code=status.HTTP_200_OK,
    summary="Get a check-in by ID",
    description="Returns a specific check-in. Returns 404 Not Found if non-existent or owned by another user.",
)
def get_checkin(
    checkin_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckinResponse:
    wellness_service = WellnessService(db)
    checkin = wellness_service.get_checkin(user_id=current_user.id, checkin_id=checkin_id)
    if not checkin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Check-in record not found.",
        )
    return CheckinResponse.model_validate(checkin)


@router.patch(
    "/{checkin_id}",
    response_model=CheckinResponse,
    status_code=status.HTTP_200_OK,
    summary="Update a check-in by ID",
    description="Updates scores, tags, mood_label, or notes. Returns 404 Not Found if non-existent or owned by another user.",
)
def update_checkin(
    checkin_id: uuid.UUID,
    req: CheckinUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CheckinResponse:
    wellness_service = WellnessService(db)
    updates = req.model_dump(exclude_unset=True)
    checkin = wellness_service.update_checkin(
        user_id=current_user.id,
        checkin_id=checkin_id,
        updates=updates,
    )
    if not checkin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Check-in record not found.",
        )
    return CheckinResponse.model_validate(checkin)


@router.delete(
    "/{checkin_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a check-in by ID",
    description="Permanently deletes a check-in. Returns 404 Not Found if non-existent or owned by another user.",
)
def delete_checkin(
    checkin_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> Response:
    wellness_service = WellnessService(db)
    deleted = wellness_service.delete_checkin(user_id=current_user.id, checkin_id=checkin_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Check-in record not found.",
        )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
