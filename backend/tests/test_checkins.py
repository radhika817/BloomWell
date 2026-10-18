import uuid
from datetime import date, timedelta
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.checkin import MoodCheckin
from app.models.user import User


def register_user(client: TestClient, email: str, name: str) -> str:
    """Helper to register a user and return access token."""
    resp = client.post(
        "/v1/auth/register",
        json={
            "email": email,
            "password": "Password123!",
            "display_name": name,
            "timezone": "Asia/Kolkata",
        },
    )
    assert resp.status_code == 201, resp.text
    return resp.json()["tokens"]["access_token"]


def test_checkin_unauthenticated(client: TestClient):
    """Endpoints require authentication and return 401 Unauthorized without token."""
    res = client.get("/v1/checkins")
    assert res.status_code == 401

    res = client.post("/v1/checkins", json={})
    assert res.status_code == 401

    res = client.get(f"/v1/checkins/{uuid.uuid4()}")
    assert res.status_code == 401

    res = client.patch(f"/v1/checkins/{uuid.uuid4()}", json={})
    assert res.status_code == 401

    res = client.delete(f"/v1/checkins/{uuid.uuid4()}")
    assert res.status_code == 401


def test_checkin_crud_and_idempotency(client: TestClient):
    """Check-in creation, idempotency replay, retrieval, update, and deletion."""
    token = register_user(client, "aarohi.crud@campus.edu", "Aarohi Sharma")
    headers = {"Authorization": f"Bearer {token}"}

    client_id = str(uuid.uuid4())
    payload = {
        "client_id": client_id,
        "local_date": str(date.today()),
        "mood_score": 4,
        "stress_score": 2,
        "energy_score": 3,
        "sleep_quality_score": 4,
        "mood_label": "calm",
        "tags": ["studying", "walk"],
        "notes": "Feeling centered and calm.",
    }

    # 1. Create check-in -> 201 Created
    create_res = client.post("/v1/checkins", json=payload, headers=headers)
    assert create_res.status_code == 201
    checkin_data = create_res.json()
    checkin_id = checkin_data["id"]
    assert checkin_data["client_id"] == client_id
    assert checkin_data["mood_score"] == 4
    assert checkin_data["mood_label"] == "calm"
    assert checkin_data["tags"] == ["studying", "walk"]
    assert checkin_data["notes"] == "Feeling centered and calm."

    # 2. Idempotency test: Same client_id returns 200 OK with same checkin ID
    replay_res = client.post("/v1/checkins", json=payload, headers=headers)
    assert replay_res.status_code == 200
    assert replay_res.json()["id"] == checkin_id

    # 3. Retrieve by ID -> 200 OK
    get_res = client.get(f"/v1/checkins/{checkin_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == checkin_id

    # 4. Update check-in -> 200 OK
    patch_res = client.patch(
        f"/v1/checkins/{checkin_id}",
        json={"mood_score": 5, "mood_label": "happy", "notes": "Felt even better later!"},
        headers=headers,
    )
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["mood_score"] == 5
    assert updated["mood_label"] == "happy"
    assert updated["notes"] == "Felt even better later!"

    # 5. Delete check-in -> 204 No Content
    del_res = client.delete(f"/v1/checkins/{checkin_id}", headers=headers)
    assert del_res.status_code == 204

    # 6. Verify deleted -> 404 Not Found
    get_deleted = client.get(f"/v1/checkins/{checkin_id}", headers=headers)
    assert get_deleted.status_code == 404


def test_checkin_validation_errors(client: TestClient):
    """Check score ranges, tag counts/lengths, and future date constraints."""
    token = register_user(client, "diya.validation@campus.edu", "Diya Patel")
    headers = {"Authorization": f"Bearer {token}"}

    # Score below 1
    res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 0,
            "stress_score": 3,
            "energy_score": 3,
        },
        headers=headers,
    )
    assert res.status_code == 422

    # Score above 5
    res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 6,
            "stress_score": 3,
            "energy_score": 3,
        },
        headers=headers,
    )
    assert res.status_code == 422

    # More than 5 tags
    res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 3,
            "stress_score": 3,
            "energy_score": 3,
            "tags": ["one", "two", "three", "four", "five", "six"],
        },
        headers=headers,
    )
    assert res.status_code == 422

    # Tag longer than 24 chars
    res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 3,
            "stress_score": 3,
            "energy_score": 3,
            "tags": ["this-tag-is-far-too-long-to-be-allowed"],
        },
        headers=headers,
    )
    assert res.status_code == 422

    # Future date > tomorrow
    future_date = date.today() + timedelta(days=3)
    res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(future_date),
            "mood_score": 3,
            "stress_score": 3,
            "energy_score": 3,
        },
        headers=headers,
    )
    assert res.status_code == 422


def test_checkin_pagination_and_date_filtering(client: TestClient):
    """Cursor-based pagination traversal and local_date filtering."""
    token = register_user(client, "meera.paginate@campus.edu", "Meera Sen")
    headers = {"Authorization": f"Bearer {token}"}

    base_date = date.today() - timedelta(days=10)
    created_ids = []

    # Insert 5 checkins on consecutive days
    for i in range(5):
        d = base_date + timedelta(days=i)
        res = client.post(
            "/v1/checkins",
            json={
                "client_id": str(uuid.uuid4()),
                "local_date": str(d),
                "mood_score": 3,
                "stress_score": 3,
                "energy_score": 3,
            },
            headers=headers,
        )
        assert res.status_code == 201
        created_ids.append(res.json()["id"])

    # Page 1: limit 2
    p1 = client.get("/v1/checkins?limit=2", headers=headers).json()
    assert len(p1["items"]) == 2
    assert p1["has_more"] is True
    assert p1["next_cursor"] is not None

    # Page 2: limit 2 with cursor
    p2 = client.get(f"/v1/checkins?limit=2&cursor={p1['next_cursor']}", headers=headers).json()
    assert len(p2["items"]) == 2
    assert p2["has_more"] is True
    assert p2["next_cursor"] is not None

    # Page 3: final item
    p3 = client.get(f"/v1/checkins?limit=2&cursor={p2['next_cursor']}", headers=headers).json()
    assert len(p3["items"]) == 1
    assert p3["has_more"] is False

    # Date filtering
    filter_from = str(base_date + timedelta(days=1))
    filter_to = str(base_date + timedelta(days=2))
    filtered = client.get(
        f"/v1/checkins?from_date={filter_from}&to_date={filter_to}",
        headers=headers,
    ).json()
    assert len(filtered["items"]) == 2

    # Inverted date filter returns 422
    inv = client.get(
        f"/v1/checkins?from_date={filter_to}&to_date={filter_from}",
        headers=headers,
    )
    assert inv.status_code == 422


def test_checkin_two_account_isolation(client: TestClient):
    """
    CRITICAL RULE 13 & 404-NOT-403:
    User B must NEVER be able to read, update, or delete User A's check-in.
    The response MUST be 404 Not Found (never 403) to prevent resource leakage.
    """
    token_a = register_user(client, "user.a@campus.edu", "User A")
    token_b = register_user(client, "user.b@campus.edu", "User B")

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A creates a check-in
    create_res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 4,
            "stress_score": 2,
            "energy_score": 4,
            "notes": "User A private health notes",
        },
        headers=headers_a,
    )
    assert create_res.status_code == 201
    checkin_id = create_res.json()["id"]

    # User B attempts to read User A's check-in -> 404 Not Found
    get_res = client.get(f"/v1/checkins/{checkin_id}", headers=headers_b)
    assert get_res.status_code == 404, f"Expected 404 Not Found, got {get_res.status_code}"

    # User B attempts to update User A's check-in -> 404 Not Found
    patch_res = client.patch(
        f"/v1/checkins/{checkin_id}",
        json={"mood_score": 1},
        headers=headers_b,
    )
    assert patch_res.status_code == 404, f"Expected 404 Not Found, got {patch_res.status_code}"

    # User B attempts to delete User A's check-in -> 404 Not Found
    del_res = client.delete(f"/v1/checkins/{checkin_id}", headers=headers_b)
    assert del_res.status_code == 404, f"Expected 404 Not Found, got {del_res.status_code}"

    # User B list contains 0 check-ins
    list_b = client.get("/v1/checkins", headers=headers_b).json()
    assert len(list_b["items"]) == 0

    # User A can still retrieve the check-in intact
    get_a = client.get(f"/v1/checkins/{checkin_id}", headers=headers_a)
    assert get_a.status_code == 200
    assert get_a.json()["mood_score"] == 4


def test_checkin_cascade_delete(client: TestClient, db_session: Session):
    """When a user is deleted, their check-ins are deleted by ON DELETE CASCADE."""
    token = register_user(client, "cascade.user@campus.edu", "Cascade User")
    headers = {"Authorization": f"Bearer {token}"}

    create_res = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 3,
            "stress_score": 3,
            "energy_score": 3,
        },
        headers=headers,
    )
    assert create_res.status_code == 201
    checkin_id = uuid.UUID(create_res.json()["id"])

    # Locate user and delete from db_session
    user = db_session.scalars(select(User).where(User.email == "cascade.user@campus.edu")).first()
    assert user is not None
    db_session.delete(user)
    db_session.commit()

    # Verify check-in is cascade deleted
    checkin = db_session.scalars(select(MoodCheckin).where(MoodCheckin.id == checkin_id)).first()
    assert checkin is None
