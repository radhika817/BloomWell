import uuid
from datetime import date, datetime, timedelta, timezone
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import (
    create_access_token,
    create_step_up_token,
    generate_raw_refresh_token,
    hash_password,
    hash_refresh_token,
)
from app.models.academic_event import AcademicEvent
from app.models.activity import Activity, UserActivityLog
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.journal import JournalEntry
from app.models.preference import UserPreference
from app.models.resource import (
    CostType,
    Resource,
    ResourceCategory,
    ResourceReport,
    VerificationStatus,
)
from app.models.study_plan import StudyPlan, StudyPlanItem
from app.models.token import RefreshToken
from app.models.user import User


def _setup_full_user(db: Session, prefix: str):
    user = User(
        email=f"{prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("Password123!"),
        display_name=f"Full User {prefix}",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    pref = UserPreference(user_id=user.id, timezone="UTC", language="en")
    rt = RefreshToken(
        token_hash=hash_refresh_token(generate_raw_refresh_token()),
        user_id=user.id,
        family_id=uuid.uuid4(),
        expires_at=datetime.now(timezone.utc) + timedelta(days=7),
    )
    checkin = MoodCheckin(
        user_id=user.id,
        client_id=uuid.uuid4(),
        local_date=date.today(),
        mood_score=5,
        stress_score=2,
        energy_score=4,
    )
    journal = JournalEntry(
        user_id=user.id,
        client_id=uuid.uuid4(),
        title="Journal",
        body="Sensitive text",
    )
    academic = AcademicEvent(
        user_id=user.id,
        title="Midterm",
        event_date=date.today(),
    )
    cycle = CycleLog(
        user_id=user.id,
        period_start=date.today(),
    )
    plan = StudyPlan(
        user_id=user.id,
        week_start=date.today(),
        days=7,
    )
    db.add_all([pref, rt, checkin, journal, academic, cycle, plan])
    db.commit()

    # Create a resource and a report by this user
    res = Resource(
        name=f"Clinic {prefix}",
        category=ResourceCategory.HEALTH_CLINIC.value,
        description="Demo clinic",
        cost=CostType.FREE.value,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.com/clinic",
        last_verified_at=date.today(),
        is_published=True,
    )
    db.add(res)
    db.commit()
    db.refresh(res)

    report = ResourceReport(
        resource_id=res.id,
        reporter_id=user.id,
        reason="outdated",
        note="Schedule changed",
    )
    db.add(report)
    db.commit()
    db.refresh(report)

    access_token = create_access_token(user.id, user.role)
    step_up_token = create_step_up_token(user.id)

    return user, access_token, step_up_token, report.id, res.id


def test_deletion_requires_both_tokens_and_exact_confirm(client: TestClient, db_session: Session):
    user, access_token, step_up_token, report_id, res_id = _setup_full_user(db_session, "del_reqs")

    headers_both = {
        "Authorization": f"Bearer {access_token}",
        "X-Reauth-Token": step_up_token,
    }

    # 1. Missing confirm body -> 422
    res = client.request("DELETE", "/v1/me", json={}, headers=headers_both)
    assert res.status_code == 422

    # 2. Wrong confirm text -> 422
    res = client.request("DELETE", "/v1/me", json={"confirm": "delete"}, headers=headers_both)
    assert res.status_code == 422

    # 3. Missing step-up token -> 401
    res = client.request(
        "DELETE",
        "/v1/me",
        json={"confirm": "DELETE"},
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert res.status_code == 401


def test_deletion_removes_user_data_and_preserves_other_user(client: TestClient, db_session: Session):
    user_a, token_a, step_up_a, rep_a_id, res_a_id = _setup_full_user(db_session, "del_a")
    user_b, token_b, step_up_b, rep_b_id, res_b_id = _setup_full_user(db_session, "del_b")

    # Delete User A
    res = client.request(
        "DELETE",
        "/v1/me",
        json={"confirm": "DELETE"},
        headers={
            "Authorization": f"Bearer {token_a}",
            "X-Reauth-Token": step_up_a,
        },
    )
    assert res.status_code == 204

    # 1. User A row deleted
    assert db_session.query(User).filter_by(id=user_a.id).first() is None

    # 2. All User A private rows deleted
    assert db_session.query(UserPreference).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(RefreshToken).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(MoodCheckin).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(JournalEntry).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(AcademicEvent).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(CycleLog).filter_by(user_id=user_a.id).first() is None
    assert db_session.query(StudyPlan).filter_by(user_id=user_a.id).first() is None

    # 3. User A's resource report survives with reporter_id = None
    rep_a = db_session.query(ResourceReport).filter_by(id=rep_a_id).first()
    assert rep_a is not None
    assert rep_a.reporter_id is None

    # 4. Old access token for A immediately fails with 401
    res_me_a = client.get("/v1/me", headers={"Authorization": f"Bearer {token_a}"})
    assert res_me_a.status_code == 401

    # 5. User B data completely untouched
    user_b_db = db_session.query(User).filter_by(id=user_b.id).first()
    assert user_b_db is not None
    assert db_session.query(MoodCheckin).filter_by(user_id=user_b.id).count() == 1
    assert db_session.query(JournalEntry).filter_by(user_id=user_b.id).count() == 1
    rep_b = db_session.query(ResourceReport).filter_by(id=rep_b_id).first()
    assert rep_b is not None
    assert rep_b.reporter_id == user_b.id
    res_me_b = client.get("/v1/me", headers={"Authorization": f"Bearer {token_b}"})
    assert res_me_b.status_code == 200


def test_deletion_transaction_rollback_on_failure(db_session: Session, monkeypatch):
    from app.services.deletion_service import deletion_registry

    user, token, step_up, rep_id, res_id = _setup_full_user(db_session, "rollback")
    target_id = user.id

    def failing_deleter(db: Session, uid: uuid.UUID):
        raise RuntimeError("Simulated failure during deletion cascade")

    monkeypatch.setitem(deletion_registry._deleters, "fault_injection", failing_deleter)

    try:
        deletion_registry.delete_user_account(db_session, target_id)
        assert False, "Should have failed"
    except RuntimeError:
        pass

    # User and data must still exist intact after rollback
    user_db = db_session.query(User).filter_by(id=target_id).first()
    assert user_db is not None
    assert db_session.query(MoodCheckin).filter_by(user_id=target_id).count() == 1
