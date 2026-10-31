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


from typing import Optional
from fastapi import Query
from app.schemas.resource import ResourceReportListResponse
from app.services.resource_report_service import ResourceReportService


@router.get(
    "/resource-reports",
    response_model=ResourceReportListResponse,
    status_code=status.HTTP_200_OK,
    summary="Get caller's own submitted resource reports",
    description="Returns reports submitted by the authenticated user strictly scoped to their account.",
)
def get_my_resource_reports(
    limit: int = Query(20, ge=1, le=100, description="Items per page"),
    cursor: Optional[str] = Query(None, description="Cursor for pagination"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ResourceReportListResponse:
    service = ResourceReportService(db)
    return service.get_my_reports(user_id=current_user.id, limit=limit, cursor=cursor)


from app.core.security import (
    create_step_up_token,
    rate_limit,
    verify_dummy_password,
    verify_password,
)
from app.schemas.auth import ReauthRequest, ReauthResponse

# Rate limiters for step-up reauthentication:
# 5 attempts per minute per IP, 5 attempts per minute per user
reauth_ip_limiter = rate_limit(max_requests=5, window_seconds=60)
reauth_user_limiter = rate_limit(
    max_requests=5,
    window_seconds=60,
    key_func=lambda req: getattr(req.state, "user_id", "anonymous"),
)


@router.post(
    "/reauth",
    response_model=ReauthResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(reauth_ip_limiter)],
    summary="Step-up re-authentication",
    description="Verifies the caller's password in constant time and returns a 5-minute step-up token for sensitive operations.",
)
def reauthenticate(
    req: ReauthRequest,
    current_user: User = Depends(get_current_user),
) -> ReauthResponse:
    # Check rate limit per user
    reauth_user_limiter.check_rate_limit(str(current_user.id))

    # Constant-time password verification
    if not verify_password(req.password, current_user.password_hash):
        verify_dummy_password(req.password)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect password.",
        )

    step_up_token = create_step_up_token(current_user.id)
    return ReauthResponse(
        step_up_token=step_up_token,
        token_type="bearer",
        expires_in=300,
    )


import json
from fastapi.responses import Response
from app.api.deps import require_step_up
from app.models.account_event import AccountEventType
from app.repositories.account_event_repository import AccountEventRepository
from app.services.export_service import ExportLimitExceededException, export_registry

# Rate limiter for export: 3 per user per day (86400 seconds)
export_user_limiter = rate_limit(
    max_requests=3,
    window_seconds=86400,
    key_func=lambda req: getattr(req.state, "user_id", "anonymous"),
)


@router.get(
    "/export",
    status_code=status.HTTP_200_OK,
    summary="Export all personal data",
    description="Generates an on-the-fly JSON export of the caller's complete data bundle. Requires step-up token in X-Reauth-Token header.",
)
def export_my_data(
    current_user: User = Depends(require_step_up),
    db: Session = Depends(get_db),
) -> Response:
    # 1. Enforce 3 exports per day per user rate limit
    export_user_limiter.check_rate_limit(str(current_user.id))

    # 2. Build export document
    try:
        export_doc = export_registry.export_all(db, current_user.id)
    except ExportLimitExceededException as e:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail={
                "code": "EXPORT_TOO_LARGE",
                "message": str(e),
                "total_records": e.count,
                "max_records": e.max_records,
            },
        )

    # 3. Record account_event: export_requested (no payload, no user content)
    event_repo = AccountEventRepository(db)
    event_repo.record_event(current_user.id, AccountEventType.EXPORT_REQUESTED)

    # 4. Serialize to JSON and return with required headers
    content_bytes = json.dumps(export_doc, indent=2).encode("utf-8")

    return Response(
        content=content_bytes,
        media_type="application/json",
        headers={
            "Content-Disposition": 'attachment; filename="bloomwell-data-export.json"',
            "Cache-Control": "no-store",
            "Content-Type": "application/json",
        },
    )


from app.schemas.user import AccountDeleteRequest
from app.services.deletion_service import deletion_registry


@router.delete(
    "",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete account and all personal data",
    description="Permanently deletes the caller's account and all associated personal data in a single transaction. Requires X-Reauth-Token header and confirmation body.",
)
def delete_my_account(
    req: AccountDeleteRequest,
    current_user: User = Depends(require_step_up),
    db: Session = Depends(get_db),
) -> Response:
    # Explicit confirmation already validated by Pydantic (confirm == "DELETE")
    deletion_registry.delete_user_account(db, current_user.id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


from app.core.config import settings
from app.schemas.consent import (
    AIConsentUpdateResponse,
    AIRecommendationsConsentDetail,
    ConsentsOverviewResponse,
    CycleConsentDetail,
    JournalAIConsentDetail,
    ToggleConsentRequest,
)


@router.get(
    "/consents",
    response_model=ConsentsOverviewResponse,
    status_code=status.HTTP_200_OK,
    summary="Get user consent overview",
    description="Returns an overview of all feature and privacy consents, timestamps, and AI availability status.",
)
def get_my_consents(
    current_user: User = Depends(get_current_user),
) -> ConsentsOverviewResponse:
    pref = current_user.preferences
    ai_available = settings.AI_PROVIDER.lower() not in ("disabled", "off", "none", "")

    return ConsentsOverviewResponse(
        cycle_tracking=CycleConsentDetail(
            enabled=pref.cycle_tracking_enabled if pref else False,
            enabled_at=pref.cycle_tracking_consent_at if pref else None,
        ),
        planner_cycle=CycleConsentDetail(
            enabled=pref.planner_cycle_consent_at is not None if pref else False,
            enabled_at=pref.planner_cycle_consent_at if pref else None,
        ),
        ai_recommendations=AIRecommendationsConsentDetail(
            enabled=pref.ai_recommendations_enabled if pref else False,
        ),
        journal_ai=JournalAIConsentDetail(
            enabled=pref.journal_ai_consent_at is not None if pref else False,
            consented_at=pref.journal_ai_consent_at if pref else None,
        ),
        ai_available=ai_available,
        reminders_enabled=pref.reminders_enabled if pref else True,
    )


@router.put(
    "/consents/ai-recommendations",
    response_model=AIConsentUpdateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update AI recommendations consent",
    description="Toggle AI recommendations consent. Responses honestly indicate whether AI features are currently available.",
)
def update_ai_recommendations_consent(
    req: ToggleConsentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIConsentUpdateResponse:
    pref = current_user.preferences
    if not pref:
        pref = UserPreference(user_id=current_user.id)
        db.add(pref)

    pref.ai_recommendations_enabled = req.enabled

    # Write consent_changed event (no payload)
    event_repo = AccountEventRepository(db)
    event_repo.record_event(current_user.id, AccountEventType.CONSENT_CHANGED)

    db.commit()
    db.refresh(pref)

    ai_available = settings.AI_PROVIDER.lower() not in ("disabled", "off", "none", "")
    return AIConsentUpdateResponse(
        enabled=pref.ai_recommendations_enabled,
        consented_at=None,
        ai_available=ai_available,
    )


@router.put(
    "/consents/journal-ai",
    response_model=AIConsentUpdateResponse,
    status_code=status.HTTP_200_OK,
    summary="Update Journal AI reflection consent",
    description="Toggle Journal AI reflection consent. Responses honestly indicate whether AI features are currently available.",
)
def update_journal_ai_consent(
    req: ToggleConsentRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> AIConsentUpdateResponse:
    from datetime import datetime, timezone

    pref = current_user.preferences
    if not pref:
        pref = UserPreference(user_id=current_user.id)
        db.add(pref)

    if req.enabled:
        pref.journal_ai_consent_at = datetime.now(timezone.utc)
    else:
        pref.journal_ai_consent_at = None

    # Write consent_changed event (no payload)
    event_repo = AccountEventRepository(db)
    event_repo.record_event(current_user.id, AccountEventType.CONSENT_CHANGED)

    db.commit()
    db.refresh(pref)

    ai_available = settings.AI_PROVIDER.lower() not in ("disabled", "off", "none", "")
    return AIConsentUpdateResponse(
        enabled=pref.journal_ai_consent_at is not None,
        consented_at=pref.journal_ai_consent_at,
        ai_available=ai_available,
    )

