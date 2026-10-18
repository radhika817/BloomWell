from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    generate_raw_refresh_token,
    hash_password,
    hash_refresh_token,
    rate_limit,
    verify_dummy_password,
    verify_password,
)
from app.db.session import get_db
from app.repositories.refresh_token_repository import RefreshTokenRepository
from app.repositories.user_repository import UserRepository
from app.schemas.auth import (
    AuthSuccessResponse,
    LoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
)
from app.schemas.user import UserProfileResponse

router = APIRouter(prefix="/auth", tags=["Authentication"])

# Rate limiters (in-memory per-process)
# Register & Refresh: 10 per minute per IP
register_rate_limiter = rate_limit(max_requests=10, window_seconds=60)
refresh_rate_limiter = rate_limit(max_requests=20, window_seconds=60)
# Login rate limiters: 15 per minute per IP
login_ip_limiter = rate_limit(max_requests=15, window_seconds=60)
# Login rate limiter per email: 5 attempts per minute
login_email_limiter = rate_limit(max_requests=5, window_seconds=60)


@router.post(
    "/register",
    response_model=AuthSuccessResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(register_rate_limiter)],
    summary="Register a new student account",
    description="Creates a new account and associated user preferences with safe defaults.",
)
def register(
    req: RegisterRequest,
    db: Session = Depends(get_db),
) -> AuthSuccessResponse:
    user_repo = UserRepository(db)
    token_repo = RefreshTokenRepository(db)

    # 1. Check duplicate email (normalized)
    existing_user = user_repo.get_by_email(req.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="An account with this email address already exists.",
        )

    # 2. Hash password with Argon2id and create user with safe preferences
    pwd_hash = hash_password(req.password)
    user = user_repo.create(
        email=req.email,
        password_hash=pwd_hash,
        display_name=req.display_name,
        timezone=req.timezone or "UTC",
    )

    # 3. Issue initial JWT access token & opaque refresh token
    access_token = create_access_token(user.id, user.role)
    raw_refresh = generate_raw_refresh_token()
    token_repo.create(user.id, hash_refresh_token(raw_refresh))

    return AuthSuccessResponse(
        tokens=TokenResponse(
            access_token=access_token,
            refresh_token=raw_refresh,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        ),
        user=UserProfileResponse(
            id=user.id,
            display_name=user.display_name,
            role=user.role,
            created_at=user.created_at,
            language=user.preferences.language if user.preferences else "en",
            timezone=user.preferences.timezone if user.preferences else "UTC",
        ),
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(login_ip_limiter)],
    summary="Authenticate and receive token pair",
    description="Validates credentials. Rejects invalid credentials with a uniform 401 error.",
)
def login(
    req: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> TokenResponse:
    # Per-email rate limiting on login
    login_email_limiter.check_rate_limit(f"email:{req.email}")

    user_repo = UserRepository(db)
    token_repo = RefreshTokenRepository(db)

    user = user_repo.get_by_email(req.email)

    if not user:
        # Constant-time dummy verification to mitigate timing attacks on account enumeration
        verify_dummy_password(req.password)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not verify_password(req.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Issue token pair
    access_token = create_access_token(user.id, user.role)
    raw_refresh = generate_raw_refresh_token()
    token_repo.create(user.id, hash_refresh_token(raw_refresh))

    return TokenResponse(
        access_token=access_token,
        refresh_token=raw_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    status_code=status.HTTP_200_OK,
    dependencies=[Depends(refresh_rate_limiter)],
    summary="Rotate refresh token",
    description="Rotates opaque refresh token. Revokes entire family on token reuse.",
)
def refresh_tokens(
    req: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    token_repo = RefreshTokenRepository(db)
    user_repo = UserRepository(db)

    token_hash = hash_refresh_token(req.refresh_token)
    token_record = token_repo.get_by_token_hash(token_hash)

    if not token_record:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or revoked refresh token.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Token reuse detection: if token is already revoked or replaced, revoke family immediately
    if token_record.revoked_at is not None or token_record.replaced_by is not None:
        token_repo.revoke_family(token_record.family_id)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token reuse detected. Token family has been revoked.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Expiry verification
    now = datetime.now(timezone.utc)
    expires_at = token_record.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at <= now:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # User active check
    user = user_repo.get_by_id(token_record.user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account associated with token no longer exists.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Perform atomic rotation
    raw_new_refresh = generate_raw_refresh_token()
    new_token_hash = hash_refresh_token(raw_new_refresh)
    token_repo.rotate(token_record, new_token_hash)

    new_access_token = create_access_token(user.id, user.role)

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=raw_new_refresh,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Logout user and revoke token family",
    description="Revokes the token family associated with the presented refresh token. Idempotent.",
)
def logout(
    req: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> Response:
    token_repo = RefreshTokenRepository(db)
    token_hash = hash_refresh_token(req.refresh_token)
    token_record = token_repo.get_by_token_hash(token_hash)

    if token_record:
        token_repo.revoke_family(token_record.family_id)

    return Response(status_code=status.HTTP_204_NO_CONTENT)
