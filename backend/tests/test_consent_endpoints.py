from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.cycle import CycleLog
from app.models.study_plan import StudyPlan, StudyPlanMode
from app.models.user import User


def register_user(client: TestClient, email: str, name: str) -> tuple[str, str]:
    res = client.post(
        "/v1/auth/register",
        json={
            "email": email,
            "password": "Password123!",
            "display_name": name,
            "timezone": "UTC",
        },
    )
    assert res.status_code == 201
    data = res.json()
    return data["user"]["id"], data["tokens"]["access_token"]


def test_planner_cycle_consent_requires_cycle_tracking(client: TestClient):
    """Enabling planner cycle consent requires cycle tracking enabled; otherwise 409 cycle_tracking_required."""
    _, token = register_user(client, "consent.user1@campus.edu", "Consent User 1")
    headers = {"Authorization": f"Bearer {token}"}

    # Initial state
    res_get = client.get("/v1/me/planner-cycle-consent", headers=headers)
    assert res_get.status_code == 200
    assert res_get.json()["enabled"] is False

    # Attempt to enable without cycle tracking
    res_put = client.put(
        "/v1/me/planner-cycle-consent",
        json={"enabled": True},
        headers=headers,
    )
    assert res_put.status_code == 409
    err = res_put.json()
    assert err["code"] == "cycle_tracking_required"

    # Now enable cycle tracking
    res_track = client.put(
        "/v1/me/cycle-tracking",
        json={"cycle_tracking_enabled": True},
        headers=headers,
    )
    assert res_track.status_code == 200
    assert res_track.json()["cycle_tracking_enabled"] is True

    # Now enabling planner cycle consent succeeds
    res_put2 = client.put(
        "/v1/me/planner-cycle-consent",
        json={"enabled": True},
        headers=headers,
    )
    assert res_put2.status_code == 200
    data = res_put2.json()
    assert data["enabled"] is True
    assert data["consent_recorded_at"] is not None


def test_disabling_consent_deletes_cycle_plans_only(client: TestClient, db_session: Session):
    """Disabling consent deletes only plans where uses_cycle_data is True; non-cycle plans survive."""
    user_id_a, token_a = register_user(client, "user.a@campus.edu", "User A")
    user_id_b, token_b = register_user(client, "user.b@campus.edu", "User B")
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # Enable cycle tracking and planner consent for user A
    client.put("/v1/me/cycle-tracking", json={"cycle_tracking_enabled": True}, headers=headers_a)
    client.put("/v1/me/planner-cycle-consent", json={"enabled": True}, headers=headers_a)

    # Seed study plans for user A: one cycle-derived, one non-cycle
    plan_cycle_a = StudyPlan(
        user_id=user_id_a,
        week_start=date(2026, 11, 2),
        days=7,
        mode=StudyPlanMode.DEFAULT.value,
        uses_cycle_data=True,
    )
    plan_non_cycle_a = StudyPlan(
        user_id=user_id_a,
        week_start=date(2026, 11, 9),
        days=7,
        mode=StudyPlanMode.DEFAULT.value,
        uses_cycle_data=False,
    )
    # Seed study plan for user B
    plan_cycle_b = StudyPlan(
        user_id=user_id_b,
        week_start=date(2026, 11, 2),
        days=7,
        mode=StudyPlanMode.DEFAULT.value,
        uses_cycle_data=True,
    )
    db_session.add_all([plan_cycle_a, plan_non_cycle_a, plan_cycle_b])
    db_session.commit()

    # User A revokes consent
    res_revoke = client.put(
        "/v1/me/planner-cycle-consent",
        json={"enabled": False},
        headers=headers_a,
    )
    assert res_revoke.status_code == 200
    revoke_data = res_revoke.json()
    assert revoke_data["enabled"] is False
    assert revoke_data["consent_recorded_at"] is None
    assert revoke_data["deleted_cycle_plans_count"] == 1

    # Verify database state
    assert db_session.get(StudyPlan, plan_cycle_a.id) is None
    assert db_session.get(StudyPlan, plan_non_cycle_a.id) is not None
    # User B's cycle plan is completely untouched
    assert db_session.get(StudyPlan, plan_cycle_b.id) is not None


def test_cycle_tracking_off_or_delete_data_cleans_up_plans(client: TestClient, db_session: Session):
    """Turning off cycle tracking or delete_data=True deletes cycle-derived plans and returns counts only."""
    user_id, token = register_user(client, "tracking.test@campus.edu", "Track User")
    headers = {"Authorization": f"Bearer {token}"}

    client.put("/v1/me/cycle-tracking", json={"cycle_tracking_enabled": True}, headers=headers)
    client.put("/v1/me/planner-cycle-consent", json={"enabled": True}, headers=headers)

    # Seed a cycle log and a cycle plan
    cycle = CycleLog(user_id=user_id, period_start=date(2026, 10, 1), period_end=date(2026, 10, 5))
    plan = StudyPlan(user_id=user_id, week_start=date(2026, 11, 16), uses_cycle_data=True)
    db_session.add_all([cycle, plan])
    db_session.commit()

    # Call PUT /v1/me/cycle-tracking with delete_data=True and cycle_tracking_enabled=False
    res = client.put(
        "/v1/me/cycle-tracking",
        json={"cycle_tracking_enabled": False, "delete_data": True},
        headers=headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["cycle_tracking_enabled"] is False
    assert data["deleted_cycle_plans_count"] == 1
    assert data["deleted_cycle_records_count"] == 1

    assert db_session.get(StudyPlan, plan.id) is None
    assert db_session.get(CycleLog, cycle.id) is None


def test_two_account_isolation_consent_endpoints(client: TestClient):
    """Verify User B cannot access or affect User A's consent status."""
    _, token_a = register_user(client, "iso.a@campus.edu", "A")
    _, token_b = register_user(client, "iso.b@campus.edu", "B")
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    client.put("/v1/me/cycle-tracking", json={"cycle_tracking_enabled": True}, headers=headers_a)
    client.put("/v1/me/planner-cycle-consent", json={"enabled": True}, headers=headers_a)

    # Check User B is still False
    res_b = client.get("/v1/me/planner-cycle-consent", headers=headers_b)
    assert res_b.json()["enabled"] is False
    res_track_b = client.get("/v1/me/cycle-tracking", headers=headers_b)
    assert res_track_b.json()["cycle_tracking_enabled"] is False


def test_consents_overview_and_ai_consent_endpoints(client: TestClient, db_session: Session):
    user_id, token = register_user(client, "consent.overview@campus.edu", "Overview User")
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Initial overview
    res = client.get("/v1/me/consents", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert data["cycle_tracking"]["enabled"] is False
    assert data["planner_cycle"]["enabled"] is False
    assert data["ai_recommendations"]["enabled"] is False
    assert data["journal_ai"]["enabled"] is False
    assert data["ai_available"] is False  # AI_PROVIDER is disabled in tests
    assert data["reminders_enabled"] is True

    # 2. Toggle AI recommendations
    res_ai_rec = client.put(
        "/v1/me/consents/ai-recommendations",
        json={"enabled": True},
        headers=headers,
    )
    assert res_ai_rec.status_code == 200
    rec_data = res_ai_rec.json()
    assert rec_data["enabled"] is True
    assert rec_data["ai_available"] is False

    # 3. Toggle Journal AI
    res_j_ai = client.put(
        "/v1/me/consents/journal-ai",
        json={"enabled": True},
        headers=headers,
    )
    assert res_j_ai.status_code == 200
    j_data = res_j_ai.json()
    assert j_data["enabled"] is True
    assert j_data["consented_at"] is not None
    assert j_data["ai_available"] is False

    # 4. Re-check overview reflects updates
    res_overview2 = client.get("/v1/me/consents", headers=headers)
    assert res_overview2.status_code == 200
    data2 = res_overview2.json()
    assert data2["ai_recommendations"]["enabled"] is True
    assert data2["journal_ai"]["enabled"] is True
    assert data2["journal_ai"]["consented_at"] is not None

    # 5. Revoking Journal AI is immediate
    res_revoke = client.put(
        "/v1/me/consents/journal-ai",
        json={"enabled": False},
        headers=headers,
    )
    assert res_revoke.status_code == 200
    assert res_revoke.json()["enabled"] is False
    assert res_revoke.json()["consented_at"] is None

    # 6. Verify account_events written with consent_changed (no payload)
    from app.models.account_event import AccountEvent, AccountEventType
    import uuid
    events = (
        db_session.query(AccountEvent)
        .filter_by(user_id=uuid.UUID(user_id), event_type=AccountEventType.CONSENT_CHANGED)
        .all()
    )
    # 3 PUT requests -> 3 events
    assert len(events) == 3
