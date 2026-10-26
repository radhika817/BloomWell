from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
from app.schemas.consent import (
    CycleTrackingStatusResponse,
    CycleTrackingUpdateRequest,
    PlannerCycleConsentRequest,
    PlannerCycleConsentResponse,
)
from app.schemas.user import PreferencesUpdateRequest, UserProfileResponse

router = APIRouter(prefix="/me", tags=["Profile"])


@router.get(
    "",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Get current user profile",
    description="Returns the caller's minimal profile without sensitive tokens or credentials.",
)
def get_my_profile(
    current_user: User = Depends(get_current_user),
) -> UserProfileResponse:
    pref = current_user.preferences
    return UserProfileResponse(
        id=current_user.id,
        display_name=current_user.display_name,
        role=current_user.role,
        created_at=current_user.created_at,
        language=pref.language if pref else "en",
        timezone=pref.timezone if pref else "UTC",
    )


@router.patch(
    "/preferences",
    response_model=UserProfileResponse,
    status_code=status.HTTP_200_OK,
    summary="Update user preferences",
    description="Updates whitelisted non-consent preferences (language, timezone, reminders, discreet_notifications).",
)
def update_my_preferences(
    req: PreferencesUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserProfileResponse:
    user_repo = UserRepository(db)

    # Extract only non-null explicitly provided values
    updates = req.model_dump(exclude_unset=True)
    if updates:
        pref = user_repo.update_preferences(current_user.id, updates)
    else:
        pref = current_user.preferences

    return UserProfileResponse(
        id=current_user.id,
        display_name=current_user.display_name,
        role=current_user.role,
        created_at=current_user.created_at,
        language=pref.language if pref else "en",
        timezone=pref.timezone if pref else "UTC",
    )


@router.get(
    "/planner-cycle-consent",
    response_model=PlannerCycleConsentResponse,
    status_code=status.HTTP_200_OK,
    summary="Get Study Planner cycle consent status",
    description="Returns whether the caller has consented to using cycle records in study planning.",
)
def get_planner_cycle_consent(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PlannerCycleConsentResponse:
    user_repo = UserRepository(db)
    pref = user_repo.get_preferences(current_user.id)
    enabled = bool(pref and pref.planner_cycle_consent_at is not None)
    consent_at = pref.planner_cycle_consent_at if pref else None
    return PlannerCycleConsentResponse(
        enabled=enabled,
        consent_recorded_at=consent_at,
        deleted_cycle_plans_count=0,
    )


@router.put(
    "/planner-cycle-consent",
    response_model=PlannerCycleConsentResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Study Planner cycle consent",
    description=(
        "Enables or disables cycle inputs for study planning. Enabling requires cycle tracking "
        "to be enabled first (otherwise HTTP 409 code cycle_tracking_required). Disabling "
        "transactionally deletes all study plans that used cycle data."
    ),
)
def update_planner_cycle_consent(
    req: PlannerCycleConsentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> PlannerCycleConsentResponse:
    user_repo = UserRepository(db)
    pref = user_repo.get_preferences(current_user.id)

    if req.enabled:
        if not (pref and pref.cycle_tracking_enabled):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail={
                    "code": "cycle_tracking_required",
                    "message": "Cycle tracking must be enabled before planner cycle consent can be granted.",
                },
            )
        updated_pref, deleted_plans = user_repo.set_planner_cycle_consent(current_user.id, True)
    else:
        updated_pref, deleted_plans = user_repo.set_planner_cycle_consent(current_user.id, False)

    return PlannerCycleConsentResponse(
        enabled=req.enabled,
        consent_recorded_at=updated_pref.planner_cycle_consent_at,
        deleted_cycle_plans_count=deleted_plans,
    )


@router.get(
    "/cycle-tracking",
    response_model=CycleTrackingStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Get cycle tracking status",
    description="Returns whether cycle tracking is enabled and when consent was recorded.",
)
def get_cycle_tracking_status(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CycleTrackingStatusResponse:
    user_repo = UserRepository(db)
    pref = user_repo.get_preferences(current_user.id)
    enabled = bool(pref and pref.cycle_tracking_enabled)
    consent_at = pref.cycle_tracking_consent_at if pref else None
    return CycleTrackingStatusResponse(
        cycle_tracking_enabled=enabled,
        consent_recorded_at=consent_at,
        deleted_cycle_plans_count=0,
        deleted_cycle_records_count=0,
    )


@router.put(
    "/cycle-tracking",
    response_model=CycleTrackingStatusResponse,
    status_code=status.HTTP_200_OK,
    summary="Update cycle tracking status",
    description=(
        "Enables or disables cycle tracking. Turning tracking off or requesting delete_data "
        "transactionally deletes all study plans that used cycle data, returning counts only."
    ),
)
def update_cycle_tracking(
    req: CycleTrackingUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CycleTrackingStatusResponse:
    user_repo = UserRepository(db)
    pref, del_plans, del_cycles = user_repo.set_cycle_tracking(
        user_id=current_user.id,
        enabled=req.cycle_tracking_enabled,
        delete_data=req.delete_data,
    )
    return CycleTrackingStatusResponse(
        cycle_tracking_enabled=pref.cycle_tracking_enabled,
        consent_recorded_at=pref.cycle_tracking_consent_at,
        deleted_cycle_plans_count=del_plans,
        deleted_cycle_records_count=del_cycles,
    )

