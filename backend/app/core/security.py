import hashlib
import secrets
import time
import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Dict, List, Optional, Set, Union

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from fastapi import HTTPException, Request, status

from app.core.config import settings

# Initialize Argon2id password hasher with RFC 9106 recommended parameters
_password_hasher = PasswordHasher(
    time_cost=3,
    memory_cost=65536,
    parallelism=4,
    hash_len=32,
    salt_len=16,
)

# Precomputed valid Argon2id hash for constant-time dummy verification on unknown emails
DUMMY_ARGON2_HASH = (
    "$argon2id$v=19$m=65536,t=3,p=4$7VaSohZ7XFmPf5Av6P4TrA$Sukr/PyVciOed14juYcQR9i5mLl9EY3geEFDXh+06nM"
)

# Common passwords denylist
COMMON_PASSWORDS: Set[str] = {
    "password123",
    "password1234",
    "1234567890",
    "12345678901",
    "qwerty12345",
    "bloomwell123",
    "welcome1234",
    "letmein1234",
    "admin123456",
    "changeme123",
    "iloveyou123",
}


def validate_password_strength(password: str) -> None:
    """
    Validate that password meets security requirements:
    1. Minimum 10 characters in length.
    2. Not in the common password denylist.
    """
    if len(password) < 10:
        raise ValueError("Password must be at least 10 characters long.")
    if password.lower() in COMMON_PASSWORDS:
        raise ValueError("Password is too common or easily guessable.")


def hash_password(password: str) -> str:
    """Hash plaintext password using Argon2id."""
    return _password_hasher.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against Argon2id hash. Returns boolean."""
    try:
        return _password_hasher.verify(hashed_password, plain_password)
    except (VerifyMismatchError, VerificationError, InvalidHashError):
        return False


def verify_dummy_password(plain_password: str) -> None:
    """
    Execute dummy Argon2id verification for non-existent users so that response
    timing does not reveal account existence.
    """
    verify_password(plain_password, DUMMY_ARGON2_HASH)


def create_access_token(user_id: Union[uuid.UUID, str], role: str) -> str:
    """
    Issue a signed JWT access token (HS256) valid for ACCESS_TOKEN_EXPIRE_MINUTES.
    Claims strictly limited to: sub, role, iat, exp, jti.
    """
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_id = str(uuid.uuid4())

    payload = {
        "sub": str(user_id),
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expires_at.timestamp()),
        "jti": token_id,
    }

    return jwt.encode(payload, settings.APP_SECRET_KEY, algorithm="HS256")


def decode_access_token(token: str) -> Dict[str, Any]:
    """
    Decode and strictly validate JWT access token claims.
    Raises HTTPException(401) on missing/tampered/expired token.
    """
    try:
        payload = jwt.decode(
            token,
            settings.APP_SECRET_KEY,
            algorithms=["HS256"],
            options={
                "require": ["sub", "role", "iat", "exp", "jti"],
                "verify_signature": True,
                "verify_exp": True,
            },
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token has expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.InvalidTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token.",
            headers={"WWW-Authenticate": "Bearer"},
        )


def generate_raw_refresh_token() -> str:
    """Generate cryptographically secure random opaque refresh token string."""
    return secrets.token_urlsafe(32)


def hash_refresh_token(raw_token: str) -> str:
    """Hash raw refresh token using SHA-256 for secure database storage."""
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


class InMemoryRateLimiter:
    """
    Sliding-window in-memory rate limiter supporting custom key derive functions
    (e.g., per-IP or per-email).
    """

    def __init__(
        self,
        max_requests: int = 60,
        window_seconds: int = 60,
        key_func: Optional[Callable[[Request], str]] = None,
    ) -> None:
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.key_func = key_func
        self._records: Dict[str, List[float]] = defaultdict(list)

    def _get_client_ip(self, request: Request) -> str:
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        if request.client and request.client.host:
            return request.client.host
        return "unknown"

    def check_rate_limit(self, key: str) -> None:
        """Check and record request timestamp for given key."""
        now = time.time()
        window_start = now - self.window_seconds

        valid_timestamps = [ts for ts in self._records[key] if ts > window_start]
        self._records[key] = valid_timestamps

        if len(valid_timestamps) >= self.max_requests:
            retry_after = int(window_start + self.window_seconds - valid_timestamps[0]) + 1
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Please try again later.",
                headers={"Retry-After": str(max(1, retry_after))},
            )

        self._records[key].append(now)

    async def __call__(self, request: Request) -> None:
        key = self.key_func(request) if self.key_func else self._get_client_ip(request)
        self.check_rate_limit(key)


def rate_limit(
    max_requests: int = 60,
    window_seconds: int = 60,
    key_func: Optional[Callable[[Request], str]] = None,
) -> InMemoryRateLimiter:
    """Factory creating rate limiting dependency."""
    return InMemoryRateLimiter(
        max_requests=max_requests,
        window_seconds=window_seconds,
        key_func=key_func,
    )
