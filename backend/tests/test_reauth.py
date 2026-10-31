import time
import uuid
import jwt
import pytest
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_step_up_token,
    decode_access_token,
    decode_step_up_token,
    hash_password,
)
from app.models.user import User


def _create_user(db: Session, email_prefix: str = "reauth") -> tuple[User, str, str]:
    raw_pw = "ValidPassword123!"
    user = User(
        email=f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password(raw_pw),
        display_name="Step-up Tester",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.role)
    return user, token, raw_pw


def test_reauth_success_and_wrong_password(client: TestClient, db_session: Session):
    user, access_token, raw_pw = _create_user(db_session, "reauth_success")
    headers = {"Authorization": f"Bearer {access_token}"}

    # Wrong password -> 401 without hints
    res_fail = client.post("/v1/me/reauth", json={"password": "WrongPassword999!"}, headers=headers)
    assert res_fail.status_code == 401
    assert "Incorrect password" in res_fail.json()["message"] or "Incorrect password" in res_fail.json()["detail"]

    # Correct password -> 200 with step-up token
    res_ok = client.post("/v1/me/reauth", json={"password": raw_pw}, headers=headers)
    assert res_ok.status_code == 200
    data = res_ok.json()
    assert "step_up_token" in data
    assert data["token_type"] == "bearer"
    assert data["expires_in"] == 300

    step_up_token = data["step_up_token"]
    payload = decode_step_up_token(step_up_token)
    assert payload["sub"] == str(user.id)
    assert payload["scope"] == "reauth"
    assert "jti" in payload


def test_token_cross_usage_rejections(client: TestClient, db_session: Session):
    user, access_token, raw_pw = _create_user(db_session, "cross_usage")
    step_up_token = create_step_up_token(user.id)

    # 1. Access token cannot be used where step-up token is decoded
    with pytest.raises(Exception) as excinfo:
        decode_step_up_token(access_token)
    assert "scope" in str(excinfo.value).lower() or "invalid" in str(excinfo.value).lower()

    # 2. Step-up token cannot be used where access token is decoded
    with pytest.raises(Exception) as excinfo:
        decode_access_token(step_up_token)
    assert "step-up token cannot be used as an access token" in str(excinfo.value).lower()

    # 3. Using step-up token as Bearer auth on an endpoint returns 401
    res = client.get("/v1/me", headers={"Authorization": f"Bearer {step_up_token}"})
    assert res.status_code == 401


def test_step_up_token_expiry_and_user_mismatch(client: TestClient, db_session: Session):
    user_a, token_a, pw_a = _create_user(db_session, "user_a")
    user_b, token_b, pw_b = _create_user(db_session, "user_b")

    # Step up token for user A
    step_up_token_a = create_step_up_token(user_a.id)

    # Decode succeeds for A
    payload_a = decode_step_up_token(step_up_token_a)
    assert payload_a["sub"] == str(user_a.id)

    # Expired token test: generate an already expired step-up token
    expired_payload = {
        "sub": str(user_a.id),
        "scope": "reauth",
        "jti": str(uuid.uuid4()),
        "exp": int((datetime.now(timezone.utc) - timedelta(seconds=10)).timestamp()),
    }
    expired_token = jwt.encode(expired_payload, settings.APP_SECRET_KEY, algorithm="HS256")
    with pytest.raises(Exception) as excinfo:
        decode_step_up_token(expired_token)
    assert "expired" in str(excinfo.value).lower()


def test_step_up_user_mismatch_and_require_step_up(client: TestClient, db_session: Session):
    user_a, token_a, pw_a = _create_user(db_session, "user_match_a")
    user_b, token_b, pw_b = _create_user(db_session, "user_match_b")

    step_up_token_a = create_step_up_token(user_a.id)

    # Calling a step-up protected dependency (we test via require_step_up directly or via reauth validation)
    from app.api.deps import require_step_up

    # User A matches their own step-up token
    validated_a = require_step_up(x_reauth_token=step_up_token_a, current_user=user_a)
    assert validated_a.id == user_a.id

    # User B using User A's step-up token raises 401
    with pytest.raises(HTTPException) as excinfo:
        require_step_up(x_reauth_token=step_up_token_a, current_user=user_b)
    assert excinfo.value.status_code == 401
    assert "does not match" in excinfo.value.detail

    # Missing step-up token raises 401
    with pytest.raises(HTTPException) as excinfo_missing:
        require_step_up(x_reauth_token=None, current_user=user_a)
    assert excinfo_missing.value.status_code == 401
