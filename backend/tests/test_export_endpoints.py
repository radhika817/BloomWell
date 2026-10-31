import uuid
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import create_access_token, create_step_up_token, hash_password
from app.models.account_event import AccountEvent, AccountEventType
from app.models.academic_event import AcademicEvent
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.journal import JournalEntry
from app.models.preference import UserPreference
from app.models.user import User


def _setup_user_with_data(db: Session, prefix: str):
    user = User(
        email=f"{prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("Password123!"),
        display_name=f"User {prefix}",
        role="student",
    )
    pref = UserPreference(
        user_id=user.id,
        timezone="Asia/Kolkata",
        language="en",
        cycle_tracking_enabled=True,
    )
    user.preferences = pref
    db.add(user)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id, user.role)
    step_up_token = create_step_up_token(user.id)

    # Add sensitive records with unique sentinel strings
    sentinel = f"SENTINEL_{prefix}_{uuid.uuid4().hex}"
    checkin = MoodCheckin(
        user_id=user.id,
        client_id=uuid.uuid4(),
        local_date=date.today(),
        mood_score=5,
        stress_score=1,
        energy_score=4,
        notes=f"Checkin note {sentinel}",
    )
    journal = JournalEntry(
        user_id=user.id,
        client_id=uuid.uuid4(),
        title=f"Journal title {sentinel}",
        body=f"Journal body text {sentinel}",
    )
    academic = AcademicEvent(
        user_id=user.id,
        title=f"Exam {sentinel}",
        event_date=date.today(),
        event_type="exam",
    )
    cycle = CycleLog(
        user_id=user.id,
        period_start=date.today(),
    )
    db.add_all([checkin, journal, academic, cycle])
    db.commit()

    return user, access_token, step_up_token, sentinel


def test_export_requires_both_tokens(client: TestClient, db_session: Session):
    user, access_token, step_up_token, sentinel = _setup_user_with_data(db_session, "req_tokens")

    # 1. No auth headers -> 401
    res = client.get("/v1/me/export")
    assert res.status_code == 401

    # 2. Only access token -> 401 (missing step-up token)
    res = client.get("/v1/me/export", headers={"Authorization": f"Bearer {access_token}"})
    assert res.status_code == 401

    # 3. Only step-up token as Bearer -> 401 (cannot use step-up as access token)
    res = client.get("/v1/me/export", headers={"Authorization": f"Bearer {step_up_token}"})
    assert res.status_code == 401

    # 4. Access token + wrong user's step up token -> 401
    other_step_up = create_step_up_token(uuid.uuid4())
    res = client.get(
        "/v1/me/export",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": other_step_up,
        },
    )
    assert res.status_code == 401


def test_export_headers_and_event_logged(client: TestClient, db_session: Session):
    user, access_token, step_up_token, sentinel = _setup_user_with_data(db_session, "export_hdr")

    res = client.get(
        "/v1/me/export",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
    )
    assert res.status_code == 200
    assert res.headers["content-disposition"] == 'attachment; filename="bloomwell-data-export.json"'
    assert res.headers["cache-control"] == "no-store"
    assert "application/json" in res.headers["content-type"]

    data = res.json()
    assert "metadata" in data
    assert "profile" in data
    assert data["profile"]["id"] == str(user.id)
    assert "password_hash" not in str(data)

    # Check account_events recorded
    events = db_session.query(AccountEvent).filter_by(user_id=user.id).all()
    assert len(events) == 1
    assert events[0].event_type == AccountEventType.EXPORT_REQUESTED


def test_export_two_account_isolation(client: TestClient, db_session: Session):
    user_a, token_a, step_up_a, sentinel_a = _setup_user_with_data(db_session, "USER_A")
    user_b, token_b, step_up_b, sentinel_b = _setup_user_with_data(db_session, "USER_B")

    # Export User A
    res_a = client.get(
        "/v1/me/export",
        headers={
            "Authorization": f"Bearer {token_a}",
            "X-Reauth-Token": step_up_a,
        },
    )
    assert res_a.status_code == 200
    text_a = res_a.text
    assert sentinel_a in text_a
    assert sentinel_b not in text_a

    # Export User B
    res_b = client.get(
        "/v1/me/export",
        headers={
            "Authorization": f"Bearer {token_b}",
            "X-Reauth-Token": step_up_b,
        },
    )
    assert res_b.status_code == 200
    text_b = res_b.text
    assert sentinel_b in text_b
    assert sentinel_a not in text_b


def test_export_rate_limiting_enforced(client: TestClient, db_session: Session):
    user, access_token, step_up_token, sentinel = _setup_user_with_data(db_session, "export_rate")

    headers = {
        "Authorization": f"Bearer {access_token}",
        "X-Reauth-Token": step_up_token,
    }

    # First 3 should succeed
    for _ in range(3):
        res = client.get("/v1/me/export", headers=headers)
        assert res.status_code == 200

    # 4th request must fail with 429
    res4 = client.get("/v1/me/export", headers=headers)
    assert res4.status_code == 429
