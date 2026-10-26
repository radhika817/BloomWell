from datetime import date, timedelta
import uuid
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.checkin import MoodCheckin


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


def test_study_plan_generate_conflict_and_replace(client: TestClient):
    """Test generating a plan, 409 plan_exists, and replace=True."""
    _, token = register_user(client, "planner.gen@campus.edu", "Planner Gen")
    headers = {"Authorization": f"Bearer {token}"}
    week_start = date(2026, 11, 2)

    # 1. Generate new plan
    res = client.post(
        "/v1/study-plans/generate",
        json={"week_start": str(week_start), "replace": False},
        headers=headers,
    )
    assert res.status_code == 201
    data = res.json()
    assert data["week_start"] == str(week_start)
    assert data["days"] == 7
    assert len(data["items"]) == 7
    assert data["mode"] == "default"
    assert data["personalization"]["status"] == "default"
    assert data["personalization"]["checkin_days_needed"] == 14
    plan_id = data["id"]

    # 2. Re-generating without replace returns 409 plan_exists
    res_conflict = client.post(
        "/v1/study-plans/generate",
        json={"week_start": str(week_start), "replace": False},
        headers=headers,
    )
    assert res_conflict.status_code == 409
    assert res_conflict.json()["code"] == "plan_exists"

    # 3. Re-generating with replace=True succeeds
    res_replace = client.post(
        "/v1/study-plans/generate",
        json={"week_start": str(week_start), "replace": True},
        headers=headers,
    )
    assert res_replace.status_code == 201
    assert res_replace.json()["id"] != plan_id  # New plan generated


def test_study_plan_get_by_id_and_query_and_current(client: TestClient):
    """Test GET /study-plans/{id}, GET /study-plans?week_start=, and GET /current."""
    _, token = register_user(client, "planner.read@campus.edu", "Planner Read")
    headers = {"Authorization": f"Bearer {token}"}

    today = date.today()
    # Calculate Monday of this week so today is covered
    this_week_monday = today - timedelta(days=today.weekday())

    res_gen = client.post(
        "/v1/study-plans/generate",
        json={"week_start": str(this_week_monday), "replace": True},
        headers=headers,
    )
    assert res_gen.status_code == 201
    plan_id = res_gen.json()["id"]

    # GET /current
    res_current = client.get("/v1/study-plans/current", headers=headers)
    assert res_current.status_code == 200
    assert res_current.json()["id"] == plan_id

    # GET by ID
    res_id = client.get(f"/v1/study-plans/{plan_id}", headers=headers)
    assert res_id.status_code == 200
    assert res_id.json()["id"] == plan_id

    # GET by query week_start
    res_query = client.get(f"/v1/study-plans?week_start={this_week_monday}", headers=headers)
    assert res_query.status_code == 200
    assert res_query.json()["id"] == plan_id

    # GET non-existent week -> 404
    res_miss = client.get("/v1/study-plans?week_start=2025-01-01", headers=headers)
    assert res_miss.status_code == 404


def test_study_plan_item_patch_status_and_load(client: TestClient):
    """
    Test patching items:
    - status: accepted, skipped
    - status: edited with suggested_load
    - suggested_load rejected when status != edited (422)
    - unknown fields rejected (422)
    """
    _, token = register_user(client, "planner.patch@campus.edu", "Planner Patch")
    headers = {"Authorization": f"Bearer {token}"}
    week_start = date(2026, 11, 2)

    res_gen = client.post(
        "/v1/study-plans/generate",
        json={"week_start": str(week_start), "replace": True},
        headers=headers,
    )
    item_id = res_gen.json()["items"][0]["id"]

    # 1. Accept item
    res_accept = client.patch(
        f"/v1/study-plans/items/{item_id}",
        json={"status": "accepted"},
        headers=headers,
    )
    assert res_accept.status_code == 200
    assert res_accept.json()["status"] == "accepted"

    # 2. Skip item
    res_skip = client.patch(
        f"/v1/study-plans/items/{item_id}",
        json={"status": "skipped"},
        headers=headers,
    )
    assert res_skip.status_code == 200
    assert res_skip.json()["status"] == "skipped"

    # 3. Edit item with new load (light, normal, focus allowed)
    res_edit = client.patch(
        f"/v1/study-plans/items/{item_id}",
        json={"status": "edited", "suggested_load": "focus"},
        headers=headers,
    )
    assert res_edit.status_code == 200
    assert res_edit.json()["status"] == "edited"
    assert res_edit.json()["suggested_load"] == "focus"

    # 4. Error: suggested_load provided when status is 'accepted' -> 422
    res_invalid = client.patch(
        f"/v1/study-plans/items/{item_id}",
        json={"status": "accepted", "suggested_load": "light"},
        headers=headers,
    )
    assert res_invalid.status_code == 422

    # 5. Error: unknown fields rejected -> 422
    res_unknown = client.patch(
        f"/v1/study-plans/items/{item_id}",
        json={"status": "accepted", "arbitrary_field": "disallowed"},
        headers=headers,
    )
    assert res_unknown.status_code == 422


def test_study_plan_cross_account_isolation_returns_404(client: TestClient):
    """
    Verify cross-account isolation:
    User B accessing or modifying User A's study plan or items receives 404 (NEVER 403).
    User A's data remains completely unchanged.
    """
    _, token_a = register_user(client, "iso.plan.a@campus.edu", "A")
    _, token_b = register_user(client, "iso.plan.b@campus.edu", "B")
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    res_gen = client.post(
        "/v1/study-plans/generate",
        json={"week_start": "2026-11-23", "replace": True},
        headers=headers_a,
    )
    plan_a_id = res_gen.json()["id"]
    item_a_id = res_gen.json()["items"][0]["id"]

    # 1. User B tries to GET User A's plan by ID -> 404
    res_b_get = client.get(f"/v1/study-plans/{plan_a_id}", headers=headers_b)
    assert res_b_get.status_code == 404
    assert res_b_get.status_code != 403

    # 2. User B tries to DELETE User A's plan -> 404
    res_b_del = client.delete(f"/v1/study-plans/{plan_a_id}", headers=headers_b)
    assert res_b_del.status_code == 404

    # 3. User B tries to PATCH User A's item -> 404
    res_b_patch = client.patch(
        f"/v1/study-plans/items/{item_a_id}",
        json={"status": "accepted"},
        headers=headers_b,
    )
    assert res_b_patch.status_code == 404

    # 4. User A's item is completely unchanged
    res_a_check = client.get(f"/v1/study-plans/{plan_a_id}", headers=headers_a)
    assert res_a_check.status_code == 200
    assert res_a_check.json()["items"][0]["status"] == "suggested"

    # 5. User A deletes their plan -> 204
    res_a_del = client.delete(f"/v1/study-plans/{plan_a_id}", headers=headers_a)
    assert res_a_del.status_code == 204
    assert client.get(f"/v1/study-plans/{plan_a_id}", headers=headers_a).status_code == 404
