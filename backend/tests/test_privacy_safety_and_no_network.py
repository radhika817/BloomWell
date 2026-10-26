from datetime import date, timedelta
from pathlib import Path
import socket
import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.checkin import MoodCheckin
from app.models.study_plan import (
    PlanItemStatus,
    StudyPlan,
    StudyPlanItem,
    StudyPlanMode,
    SuggestedLoad,
)
from app.models.user import User
from app.services.insights_service import (
    calculate_exam_context_insights,
    calculate_weekly_insights,
)
from app.services.planner_algorithm import (
    ActivityCandidate,
    generate_study_plan_schedule,
)
from app.services.planner_service import PlannerService


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


def test_two_account_isolation_matrix(client: TestClient):
    """
    CRITICAL RULE (AGENTS.md Rule 16):
    Every feature touching private data needs a two-account isolation test.
    Verify that across all endpoints, User B receives 404 or strictly their own data,
    and User A's data remains unmodified.
    """
    user_a_id, token_a = register_user(client, "matrix.a@campus.edu", "User A")
    user_b_id, token_b = register_user(client, "matrix.b@campus.edu", "User B")
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # 1. User A generates a study plan
    week_str = "2026-11-16"
    res_gen = client.post(
        "/v1/study-plans/generate",
        json={"week_start": week_str, "replace": True},
        headers=headers_a,
    )
    assert res_gen.status_code == 201
    plan_a_id = res_gen.json()["id"]
    item_a_id = res_gen.json()["items"][0]["id"]

    # 2. User B tries to read User A's plan by ID -> 404 (never 403)
    res_b_read = client.get(f"/v1/study-plans/{plan_a_id}", headers=headers_b)
    assert res_b_read.status_code == 404

    # 3. User B tries to read User A's plan by query -> 404
    res_b_query = client.get(f"/v1/study-plans?week_start={week_str}", headers=headers_b)
    assert res_b_query.status_code == 404

    # 4. User B tries to patch User A's item -> 404
    res_b_patch = client.patch(
        f"/v1/study-plans/items/{item_a_id}",
        json={"status": "edited", "suggested_load": "focus"},
        headers=headers_b,
    )
    assert res_b_patch.status_code == 404

    # 5. User B tries to delete User A's plan -> 404
    res_b_del = client.delete(f"/v1/study-plans/{plan_a_id}", headers=headers_b)
    assert res_b_del.status_code == 404

    # 6. Verify User A's item and plan are completely unchanged
    res_a_check = client.get(f"/v1/study-plans/{plan_a_id}", headers=headers_a)
    assert res_a_check.status_code == 200
    assert res_a_check.json()["items"][0]["status"] == "suggested"

    # 7. Consent endpoints isolation: User A enables consent, User B is unaffected
    client.put("/v1/me/cycle-tracking", json={"cycle_tracking_enabled": True}, headers=headers_a)
    client.put("/v1/me/planner-cycle-consent", json={"enabled": True}, headers=headers_a)

    res_b_consent = client.get("/v1/me/planner-cycle-consent", headers=headers_b)
    assert res_b_consent.status_code == 200
    assert res_b_consent.json()["enabled"] is False

    res_b_track = client.get("/v1/me/cycle-tracking", headers=headers_b)
    assert res_b_track.status_code == 200
    assert res_b_track.json()["cycle_tracking_enabled"] is False

    # 8. Insights isolation: User A insights queries never leak to User B
    res_b_ins = client.get(f"/v1/insights/weekly?week_start={week_str}", headers=headers_b)
    assert res_b_ins.status_code == 200
    assert res_b_ins.json()["status"] == "not_enough_data"


def test_forbidden_vocabulary_scan():
    """
    CRITICAL SCOPE RULE:
    No response, message, or doc string for this feature may contain:
    - ovulation
    - fertile
    - pregnancy
    - abnormal
    - irregular
    - because of your period
    - caused by
    """
    backend_root = Path(__file__).resolve().parent.parent
    docs_root = backend_root.parent / "docs"

    target_files = [
        backend_root / "app/api/v1/study_plans.py",
        backend_root / "app/api/v1/insights.py",
        backend_root / "app/schemas/study_plan.py",
        backend_root / "app/schemas/insights.py",
        backend_root / "app/schemas/consent.py",
        backend_root / "app/services/planner_service.py",
        backend_root / "app/services/planner_algorithm.py",
        backend_root / "app/services/insights_service.py",
        backend_root / "app/models/study_plan.py",
        docs_root / "study-planner-rules.md",
    ]

    forbidden_phrases = [
        "ovulation",
        "fertile",
        "pregnancy",
        "abnormal",
        "irregular",
        "because of your period",
        "caused by",
    ]

    violations = []
    for path in target_files:
        assert path.is_file(), f"Target file does not exist: {path}"
        content = path.read_text(encoding="utf-8").lower()
        for phrase in forbidden_phrases:
            if phrase in content:
                violations.append(f"Forbidden phrase '{phrase}' found in {path.name}")

    assert not violations, "Vocabulary scan failed:\n" + "\n".join(violations)


def test_no_network_calls_in_planner_and_insights(monkeypatch, db_session: Session):
    """
    Assert that planner and insights algorithms and services make zero external network calls.
    """
    def guarded_connect(*args, **kwargs):
        raise RuntimeError("CRITICAL ERROR: External network call attempted!")

    monkeypatch.setattr(socket.socket, "connect", guarded_connect)

    # 1. Pure function planner
    plan_out = generate_study_plan_schedule(
        week_start=date(2026, 11, 2),
        daily_energy_history={date(2026, 11, 2) - timedelta(days=i): 3.5 for i in range(1, 15)},
        academic_events=[],
        cycle_consent=False,
        cycle_tracking_enabled=False,
        recorded_cycles=[],
        break_activities=[ActivityCandidate(id=uuid.uuid4())],
    )
    assert plan_out.mode == "personalized"

    # 2. Pure function insights
    ins_out = calculate_weekly_insights(
        week_checkins=[],
        baseline_checkins=[],
        week_start=date(2026, 11, 2),
    )
    assert ins_out.status == "not_enough_data"

    exam_ins = calculate_exam_context_insights(
        events=[],
        checkins=[],
        reference_date=date(2026, 11, 2),
    )
    assert exam_ins.status == "not_enough_data"

    # 3. Service call
    user = User(email="nonetwork@campus.edu", password_hash="hash", display_name="No Net")
    db_session.add(user)
    db_session.commit()

    service = PlannerService(db_session)
    res = service.generate_plan(user_id=user.id, week_start=date(2026, 11, 2), replace=True)
    assert res.week_start == date(2026, 11, 2)


def test_cascade_deletion_on_user_removal(db_session: Session):
    """
    Test cascade deletion: when a user is deleted, their study plans and items
    are completely deleted by foreign key cascade.
    """
    user = User(email="cascade.plan@campus.edu", password_hash="hash", display_name="Cascade")
    db_session.add(user)
    db_session.commit()

    plan = StudyPlan(
        user_id=user.id,
        week_start=date(2026, 12, 1),
        days=7,
        mode=StudyPlanMode.DEFAULT.value,
    )
    db_session.add(plan)
    db_session.commit()

    item = StudyPlanItem(
        study_plan_id=plan.id,
        plan_date=date(2026, 12, 1),
        suggested_load=SuggestedLoad.NORMAL.value,
        reason_codes=["DEFAULT_PLAN"],
        status=PlanItemStatus.SUGGESTED.value,
    )
    db_session.add(item)
    db_session.commit()

    plan_id = plan.id
    item_id = item.id

    # Verify rows exist
    assert db_session.get(StudyPlan, plan_id) is not None
    assert db_session.get(StudyPlanItem, item_id) is not None

    # Delete User
    db_session.delete(user)
    db_session.commit()

    # Verify cascade deletion
    assert db_session.get(StudyPlan, plan_id) is None
    assert db_session.get(StudyPlanItem, item_id) is None
