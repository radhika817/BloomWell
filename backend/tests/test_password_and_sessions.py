import uuid
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token, generate_raw_refresh_token, hash_password, hash_refresh_token
from app.models.account_event import AccountEvent, AccountEventType
from app.models.token import RefreshToken
from app.models.user import User


def _create_user_with_sessions(db: Session, prefix: str):
    pw = "InitialSecret123!"
    user = User(
        email=f"{prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password(pw),
        display_name=f"User {prefix}",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    from datetime import datetime, timedelta, timezone
    now = datetime.now(timezone.utc)
    from app.repositories.refresh_token_repository import RefreshTokenRepository
    repo = RefreshTokenRepository(db)
    # Create 2 active sessions
    repo.create(user.id, hash_refresh_token(generate_raw_refresh_token()))
    repo.create(user.id, hash_refresh_token(generate_raw_refresh_token()))

    token = create_access_token(user.id, user.role)
    return user, token, pw


def test_password_change_success_and_validations(client: TestClient, db_session: Session):
    user, token, pw = _create_user_with_sessions(db_session, "pw_change")
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Wrong current password -> 401
    res_wrong = client.post(
        "/v1/me/password",
        json={"current_password": "WrongPassword1!", "new_password": "NewValidPassword123!"},
        headers=headers,
    )
    assert res_wrong.status_code == 401

    # 2. Short new password (< 10 chars) -> 422
    res_short = client.post(
        "/v1/me/password",
        json={"current_password": pw, "new_password": "short"},
        headers=headers,
    )
    assert res_short.status_code == 422

    # 3. Password reuse -> 400
    res_reuse = client.post(
        "/v1/me/password",
        json={"current_password": pw, "new_password": pw},
        headers=headers,
    )
    assert res_reuse.status_code == 400
    assert "same as the current password" in res_reuse.json()["message"] or "same as the current password" in res_reuse.json()["detail"]

    # 4. Successful password change
    new_pw = "BrandNewSecret456!"
    res_ok = client.post(
        "/v1/me/password",
        json={"current_password": pw, "new_password": new_pw},
        headers=headers,
    )
    assert res_ok.status_code == 200
    data = res_ok.json()
    assert "access_token" in data
    assert "refresh_token" in data

    # Refresh tokens count: previously 2 active sessions were revoked, 1 fresh session created
    from app.repositories.refresh_token_repository import RefreshTokenRepository
    repo = RefreshTokenRepository(db_session)
    assert repo.count_active_sessions(user.id) == 1

    # Event logged: password_changed
    events = db_session.query(AccountEvent).filter_by(user_id=user.id).all()
    assert any(e.event_type == AccountEventType.PASSWORD_CHANGED for e in events)


def test_sessions_status_and_revoke_all(client: TestClient, db_session: Session):
    user, token, pw = _create_user_with_sessions(db_session, "sess_mgmt")
    headers = {"Authorization": f"Bearer {token}"}

    # 1. GET /me/sessions -> active_sessions == 2
    res_count = client.get("/v1/me/sessions", headers=headers)
    assert res_count.status_code == 200
    assert res_count.json()["active_sessions"] == 2

    # 2. POST /me/sessions/revoke-all -> 204
    res_revoke = client.post("/v1/me/sessions/revoke-all", headers=headers)
    assert res_revoke.status_code == 204

    # 3. GET /me/sessions -> active_sessions == 0
    res_count_after = client.get("/v1/me/sessions", headers=headers)
    assert res_count_after.status_code == 200
    assert res_count_after.json()["active_sessions"] == 0

    # 4. Event logged: sessions_revoked
    events = db_session.query(AccountEvent).filter_by(user_id=user.id).all()
    assert any(e.event_type == AccountEventType.SESSIONS_REVOKED for e in events)


def test_account_events_pagination_and_two_account_isolation(client: TestClient, db_session: Session):
    user_a, token_a, _ = _create_user_with_sessions(db_session, "events_a")
    user_b, token_b, _ = _create_user_with_sessions(db_session, "events_b")

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # Generate 3 events for User A
    from app.repositories.account_event_repository import AccountEventRepository
    event_repo = AccountEventRepository(db_session)
    event_repo.record_event(user_a.id, AccountEventType.CONSENT_CHANGED)
    event_repo.record_event(user_a.id, AccountEventType.PASSWORD_CHANGED)
    event_repo.record_event(user_a.id, AccountEventType.EXPORT_REQUESTED)

    # Generate 1 event for User B
    event_repo.record_event(user_b.id, AccountEventType.SESSIONS_REVOKED)

    # 1. Fetch User A events
    res_a = client.get("/v1/me/account-events?limit=2", headers=headers_a)
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert len(data_a["items"]) == 2
    assert data_a["has_more"] is True
    assert data_a["next_cursor"] is not None

    # Fetch page 2 for User A
    cursor = data_a["next_cursor"]
    res_a_p2 = client.get(f"/v1/me/account-events?limit=2&cursor={cursor}", headers=headers_a)
    assert res_a_p2.status_code == 200
    assert len(res_a_p2.json()["items"]) >= 1

    # 2. Fetch User B events: isolation check
    res_b = client.get("/v1/me/account-events", headers=headers_b)
    assert res_b.status_code == 200
    data_b = res_b.json()
    assert len(data_b["items"]) == 1
    assert data_b["items"][0]["event_type"] == "sessions_revoked"
