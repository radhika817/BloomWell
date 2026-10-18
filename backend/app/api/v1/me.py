from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.api.deps import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.repositories.user_repository import UserRepository
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
