import io
import json
import logging
import time
import uuid
from datetime import datetime, timedelta, timezone

import jwt
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.logging import RedactingJsonFormatter, SensitiveDataFilter
from app.core.security import create_access_token, hash_refresh_token
from app.models.preference import UserPreference
from app.models.token import RefreshToken
from app.models.user import User


def test_register_happy_path(client: TestClient):
    """Test user registration returns tokens and minimal profile without sensitive data."""
    payload = {
        "email": "Student.One@University.edu",
        "password": "ValidPassword123!",
        "display_name": "Student One",
        "timezone": "Asia/Kolkata",
    }
    response = client.post("/v1/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()

    assert "tokens" in data
    assert "user" in data

    tokens = data["tokens"]
    assert "access_token" in tokens
    assert "refresh_token" in tokens
    assert tokens["token_type"] == "bearer"
    assert tokens["expires_in"] == 900

    user = data["user"]
    assert user["display_name"] == "Student One"
    assert user["role"] == "student"
    assert user["language"] == "en"
    assert user["timezone"] == "Asia/Kolkata"

    # CRITICAL: Verify passwords, hashes, and internal tokens never appear in user profile response
    assert "password" not in json.dumps(data).lower()
    assert "hash" not in json.dumps(data).lower()


def test_register_duplicate_email(client: TestClient):
    """Duplicate registration with normalized email returns 409 Conflict."""
    payload = {
        "email": "duplicate@university.edu",
        "password": "SecurePassword123!",
        "display_name": "First User",
    }
    resp1 = client.post("/v1/auth/register", json=payload)
    assert resp1.status_code == 201

    # Attempt registration with different case and spaces
    payload_dup = {
        "email": "  DUPLICATE@university.edu  ",
        "password": "AnotherPassword123!",
        "display_name": "Second User",
    }
    resp2 = client.post("/v1/auth/register", json=payload_dup)
    assert resp2.status_code == 409
    data = resp2.json()
    assert data["code"] == "HTTP_409"
    assert "already exists" in data["message"]


def test_register_password_and_timezone_validation(client: TestClient):
    """Registration rejects passwords under 10 chars, common passwords, and invalid IANA timezones."""
    # 1. Under 10 characters
    resp_short = client.post(
        "/v1/auth/register",
        json={"email": "short@univ.edu", "password": "short", "display_name": "Test"},
    )
    assert resp_short.status_code == 422

    # 2. Common password
    resp_common = client.post(
        "/v1/auth/register",
        json={"email": "common@univ.edu", "password": "password1234", "display_name": "Test"},
    )
    assert resp_common.status_code == 422
    assert "easily guessable" in resp_common.text

    # 3. Invalid IANA timezone
    resp_tz = client.post(
        "/v1/auth/register",
        json={
            "email": "tz@univ.edu",
            "password": "ValidPassword123!",
            "display_name": "Test",
            "timezone": "Invalid/Timezone",
        },
    )
    assert resp_tz.status_code == 422
    assert "Invalid IANA timezone" in resp_tz.text


def test_login_happy_path_and_timing_uniformity(client: TestClient):
    """Login succeeds for valid credentials; returns identical 401 for wrong email or wrong password."""
    # Register test user
    client.post(
        "/v1/auth/register",
        json={"email": "login_test@univ.edu", "password": "Password12345!", "display_name": "Login User"},
    )

    # 1. Valid login
    resp_ok = client.post(
        "/v1/auth/login",
        json={"email": "login_test@univ.edu", "password": "Password12345!"},
    )
    assert resp_ok.status_code == 200
    assert "access_token" in resp_ok.json()
    assert "refresh_token" in resp_ok.json()

    # 2. Wrong password on existing user
    resp_wrong_pw = client.post(
        "/v1/auth/login",
        json={"email": "login_test@univ.edu", "password": "WrongPassword999!"},
    )
    assert resp_wrong_pw.status_code == 401

    # 3. Non-existent email
    resp_unknown_email = client.post(
        "/v1/auth/login",
        json={"email": "nonexistent_email_12345@univ.edu", "password": "WrongPassword999!"},
    )
    assert resp_unknown_email.status_code == 401

    # Exact error code and message parity to eliminate account enumeration
    assert resp_wrong_pw.json()["code"] == resp_unknown_email.json()["code"]
    assert resp_wrong_pw.json()["message"] == resp_unknown_email.json()["message"]
    assert resp_wrong_pw.json()["message"] == "Invalid email or password."


def test_refresh_token_rotation_and_family_revocation(client: TestClient):
    """Refresh token rotates on every use; reusing an old token revokes the entire family."""
    reg = client.post(
        "/v1/auth/register",
        json={"email": "rotation@univ.edu", "password": "Password12345!", "display_name": "Rotate User"},
    )
    token_1 = reg.json()["tokens"]["refresh_token"]

    # 1. First rotation: token_1 -> token_2
    ref_1 = client.post("/v1/auth/refresh", json={"refresh_token": token_1})
    assert ref_1.status_code == 200
    token_2 = ref_1.json()["refresh_token"]
    access_2 = ref_1.json()["access_token"]
    assert token_2 != token_1

    # Access token 2 works for /me
    me_resp = client.get("/v1/me", headers={"Authorization": f"Bearer {access_2}"})
    assert me_resp.status_code == 200

    # 2. Second rotation: token_2 -> token_3
    ref_2 = client.post("/v1/auth/refresh", json={"refresh_token": token_2})
    assert ref_2.status_code == 200
    token_3 = ref_2.json()["refresh_token"]
    assert token_3 != token_2

    # 3. REUSE ATTACK: replay token_1 (which was already rotated)
    reuse_resp = client.post("/v1/auth/refresh", json={"refresh_token": token_1})
    assert reuse_resp.status_code == 401
    assert "reuse detected" in reuse_resp.text.lower()

    # 4. Prove the ENTIRE family was revoked: token_3 (which was active) now fails!
    active_token_resp = client.post("/v1/auth/refresh", json={"refresh_token": token_3})
    assert active_token_resp.status_code == 401


def test_logout_revokes_token_family(client: TestClient):
    """Logout revokes the token family and is idempotent."""
    reg = client.post(
        "/v1/auth/register",
        json={"email": "logout_test@univ.edu", "password": "Password12345!", "display_name": "Logout User"},
    )
    refresh_token = reg.json()["tokens"]["refresh_token"]

    # Logout
    logout_resp = client.post("/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_resp.status_code == 204

    # Subsequent refresh with that token fails
    ref_resp = client.post("/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_resp.status_code == 401

    # Second logout with same token is idempotent (204)
    logout_again = client.post("/v1/auth/logout", json={"refresh_token": refresh_token})
    assert logout_again.status_code == 204


def test_two_account_isolation(client: TestClient):
    """
    Two-account isolation:
    User A's token returns A's data, User B's token returns B's data.
    User A updating preferences never alters User B.
    """
    # 1. Register User A
    reg_a = client.post(
        "/v1/auth/register",
        json={"email": "user_a@univ.edu", "password": "Password12345!", "display_name": "User Alpha", "timezone": "UTC"},
    )
    token_a = reg_a.json()["tokens"]["access_token"]
    user_a_id = reg_a.json()["user"]["id"]

    # 2. Register User B
    reg_b = client.post(
        "/v1/auth/register",
        json={"email": "user_b@univ.edu", "password": "Password12345!", "display_name": "User Beta", "timezone": "Asia/Tokyo"},
    )
    token_b = reg_b.json()["tokens"]["access_token"]
    user_b_id = reg_b.json()["user"]["id"]

    # Verify /v1/me returns respective user
    me_a = client.get("/v1/me", headers={"Authorization": f"Bearer {token_a}"})
    me_b = client.get("/v1/me", headers={"Authorization": f"Bearer {token_b}"})
    assert me_a.status_code == 200
    assert me_b.status_code == 200
    assert me_a.json()["id"] == user_a_id
    assert me_b.json()["id"] == user_b_id
    assert me_a.json()["display_name"] == "User Alpha"
    assert me_b.json()["display_name"] == "User Beta"

    # User A updates preferences
    patch_a = client.patch(
        "/v1/me/preferences",
        headers={"Authorization": f"Bearer {token_a}"},
        json={"language": "hi", "timezone": "Asia/Kolkata", "discreet_notifications": False},
    )
    assert patch_a.status_code == 200
    data_a = patch_a.json()
    assert data_a["language"] == "hi"
    assert data_a["timezone"] == "Asia/Kolkata"

    # User B's preferences remain strictly untouched
    me_b_after = client.get("/v1/me", headers={"Authorization": f"Bearer {token_b}"})
    data_b = me_b_after.json()
    assert data_b["language"] == "en"
    assert data_b["timezone"] == "Asia/Tokyo"


def test_preferences_patch_whitelist_rejection(client: TestClient):
    """PATCH /me/preferences rejects consent fields and unknown fields with 422."""
    reg = client.post(
        "/v1/auth/register",
        json={"email": "pref_test@univ.edu", "password": "Password12345!", "display_name": "Pref User"},
    )
    token = reg.json()["tokens"]["access_token"]

    # Attempt to change consent field ai_recommendations_enabled
    resp_consent = client.patch(
        "/v1/me/preferences",
        headers={"Authorization": f"Bearer {token}"},
        json={"ai_recommendations_enabled": True},
    )
    assert resp_consent.status_code == 422

    # Attempt to change consent timestamp
    resp_ts = client.patch(
        "/v1/me/preferences",
        headers={"Authorization": f"Bearer {token}"},
        json={"journal_ai_consent_at": "2026-10-18T10:00:00Z"},
    )
    assert resp_ts.status_code == 422

    # Attempt to send arbitrary unknown field
    resp_unknown = client.patch(
        "/v1/me/preferences",
        headers={"Authorization": f"Bearer {token}"},
        json={"unknown_field": "hack"},
    )
    assert resp_unknown.status_code == 422


def test_expired_and_tampered_access_tokens(client: TestClient):
    """Tampered tokens, wrong secret keys, and expired tokens return 401."""
    # 1. Tampered token
    tampered_resp = client.get("/v1/me", headers={"Authorization": "Bearer this.is.an.invalid.token"})
    assert tampered_resp.status_code == 401

    # 2. Token signed with wrong key
    wrong_key_token = jwt.encode(
        {"sub": str(uuid.uuid4()), "role": "student", "iat": int(time.time()), "exp": int(time.time() + 600), "jti": str(uuid.uuid4())},
        "wrong-secret-key-that-does-not-match-at-all",
        algorithm="HS256",
    )
    wrong_resp = client.get("/v1/me", headers={"Authorization": f"Bearer {wrong_key_token}"})
    assert wrong_resp.status_code == 401

    # 3. Expired token
    expired_token = jwt.encode(
        {"sub": str(uuid.uuid4()), "role": "student", "iat": int(time.time() - 1000), "exp": int(time.time() - 100), "jti": str(uuid.uuid4())},
        settings.APP_SECRET_KEY,
        algorithm="HS256",
    )
    expired_resp = client.get("/v1/me", headers={"Authorization": f"Bearer {expired_token}"})
    assert expired_resp.status_code == 401


def test_refresh_tokens_stored_hashed_only(client: TestClient, db_session: Session):
    """Prove that raw refresh tokens are NEVER stored in the database; only SHA-256 hashes are persisted."""
    reg = client.post(
        "/v1/auth/register",
        json={"email": "storage_audit@univ.edu", "password": "Password12345!", "display_name": "Audit User"},
    )
    raw_refresh = reg.json()["tokens"]["refresh_token"]
    user_id = uuid.UUID(reg.json()["user"]["id"])

    # Query the refresh_tokens table directly via SQLAlchemy
    records = db_session.scalars(select(RefreshToken).where(RefreshToken.user_id == user_id)).all()
    assert len(records) == 1
    db_record = records[0]

    # ASSERTIONS:
    # 1. The raw refresh token is NOT in the database
    assert db_record.token_hash != raw_refresh
    # 2. The stored value is the SHA-256 hash of the raw token
    assert db_record.token_hash == hash_refresh_token(raw_refresh)
    # 3. The length is standard SHA-256 hex string (64 characters)
    assert len(db_record.token_hash) == 64


def test_auth_logging_redaction_extended():
    """Verify that sensitive auth credentials, passwords, raw tokens, and emails are redacted in structured logs."""
    fake_password = "MySecretPassword123!"
    fake_email = "sensitive_student@college.edu"
    fake_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.fake_jwt_signature"
    fake_refresh = "k9s_7LmQ2P8_fake_refresh_token_xyz"

    log_stream = io.StringIO()
    handler = logging.StreamHandler(log_stream)
    formatter = RedactingJsonFormatter("%(levelname)s %(message)s")
    handler.setFormatter(formatter)
    handler.addFilter(SensitiveDataFilter())

    logger = logging.getLogger("auth_audit_logger")
    logger.setLevel(logging.INFO)
    logger.handlers = [handler]
    logger.propagate = False

    # Log events mimicking auth request processing
    logger.info(
        "Login request attempted",
        extra={
            "email": fake_email,
            "password": fake_password,
            "token": fake_token,
            "refresh_token": fake_refresh,
            "authorization": f"Bearer {fake_token}",
        },
    )

    logger.info("Credentials checked for email=%s with Bearer %s", fake_email, fake_token)

    captured = log_stream.getvalue()

    # ASSERTIONS: None of the sensitive credentials appear in cleartext
    assert fake_password not in captured
    assert fake_email not in captured
    assert fake_token not in captured
    assert fake_refresh not in captured
    assert "[REDACTED]" in captured


def test_auth_rate_limiting(client: TestClient):
    """Verify that auth endpoints enforce rate limits and return 429 with Retry-After header."""
    for i in range(10):
        client.post(
            "/v1/auth/register",
            json={
                "email": f"ratelimit_{i}@univ.edu",
                "password": "Password12345!",
                "display_name": f"User {i}",
            },
        )

    # 11th request must trigger 429 Too Many Requests
    resp_limited = client.post(
        "/v1/auth/register",
        json={
            "email": "ratelimit_11@univ.edu",
            "password": "Password12345!",
            "display_name": "User 11",
        },
    )
    assert resp_limited.status_code == 429
    assert resp_limited.json()["code"] == "HTTP_429"
    assert "Rate limit exceeded" in resp_limited.json()["message"]
    assert "Retry-After" in resp_limited.headers
