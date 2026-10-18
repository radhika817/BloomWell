import uuid
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.journal import JournalEntry
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


def test_journal_unauthenticated(client: TestClient):
    """Endpoints require authentication and return 401 Unauthorized without token."""
    res = client.get("/v1/journal")
    assert res.status_code == 401

    res = client.post("/v1/journal", json={})
    assert res.status_code == 401

    res = client.get(f"/v1/journal/{uuid.uuid4()}")
    assert res.status_code == 401

    res = client.patch(f"/v1/journal/{uuid.uuid4()}", json={})
    assert res.status_code == 401

    res = client.delete(f"/v1/journal/{uuid.uuid4()}")
    assert res.status_code == 401


def test_journal_crud_and_idempotency(client: TestClient):
    """Journal creation, idempotency replay, retrieval, update, and deletion."""
    token = register_user(client, "aarohi.journal@campus.edu", "Aarohi Sharma")
    headers = {"Authorization": f"Bearer {token}"}

    client_id = str(uuid.uuid4())
    payload = {
        "client_id": client_id,
        "title": "Semester Reflections",
        "body": "Studying for upcoming midterms in the campus library. Feeling calm and prepared.",
    }

    # 1. Create entry -> 201 Created
    create_res = client.post("/v1/journal", json=payload, headers=headers)
    assert create_res.status_code == 201
    entry_data = create_res.json()
    entry_id = entry_data["id"]
    assert entry_data["client_id"] == client_id
    assert entry_data["title"] == "Semester Reflections"
    assert entry_data["body"] == payload["body"]

    # 2. Idempotency test: Same client_id returns 200 OK with same entry ID
    replay_res = client.post("/v1/journal", json=payload, headers=headers)
    assert replay_res.status_code == 200
    assert replay_res.json()["id"] == entry_id

    # 3. Retrieve by ID -> 200 OK
    get_res = client.get(f"/v1/journal/{entry_id}", headers=headers)
    assert get_res.status_code == 200
    assert get_res.json()["id"] == entry_id
    assert get_res.json()["body"] == payload["body"]

    # 4. Update entry -> 200 OK
    patch_res = client.patch(
        f"/v1/journal/{entry_id}",
        json={"title": "Updated Reflections", "body": "Finished the midterm early and feeling relieved."},
        headers=headers,
    )
    assert patch_res.status_code == 200
    updated = patch_res.json()
    assert updated["title"] == "Updated Reflections"
    assert updated["body"] == "Finished the midterm early and feeling relieved."

    # 5. Delete entry -> 204 No Content
    del_res = client.delete(f"/v1/journal/{entry_id}", headers=headers)
    assert del_res.status_code == 204

    # 6. Verify deleted -> 404 Not Found
    get_deleted = client.get(f"/v1/journal/{entry_id}", headers=headers)
    assert get_deleted.status_code == 404


def test_journal_validation_errors(client: TestClient):
    """Check body length limits, empty bodies, and title length constraints."""
    token = register_user(client, "diya.journal_val@campus.edu", "Diya Patel")
    headers = {"Authorization": f"Bearer {token}"}

    # Empty body
    res = client.post(
        "/v1/journal",
        json={"client_id": str(uuid.uuid4()), "title": "Test", "body": "   "},
        headers=headers,
    )
    assert res.status_code == 422

    # Title longer than 120 characters
    res = client.post(
        "/v1/journal",
        json={"client_id": str(uuid.uuid4()), "title": "A" * 121, "body": "Valid body text"},
        headers=headers,
    )
    assert res.status_code == 422

    # Body longer than 10,000 characters
    res = client.post(
        "/v1/journal",
        json={"client_id": str(uuid.uuid4()), "title": "Test", "body": "A" * 10001},
        headers=headers,
    )
    assert res.status_code == 422


def test_journal_preview_sanitization_and_no_full_body_in_list(client: TestClient):
    """
    CRITICAL PRIVACY GUARANTEE:
    GET /v1/journal returns preview (max 80 chars, normalized linebreaks)
    and strictly NEVER sends full body over the wire in list view.
    """
    token = register_user(client, "privacy.preview@campus.edu", "Privacy Student")
    headers = {"Authorization": f"Bearer {token}"}

    full_body = (
        "This is line 1.\n\n"
        "This is line 2 with important private notes that should never appear in list queries.\n\n"
        "Line 3 has more confidential reflections."
    )

    create_res = client.post(
        "/v1/journal",
        json={"client_id": str(uuid.uuid4()), "title": "Private Notes", "body": full_body},
        headers=headers,
    )
    assert create_res.status_code == 201

    list_res = client.get("/v1/journal", headers=headers)
    assert list_res.status_code == 200
    data = list_res.json()

    assert len(data["items"]) == 1
    item = data["items"][0]

    # Verify preview is <= 80 characters
    assert len(item["preview"]) <= 80
    assert "\n" not in item["preview"]
    assert "line 1" in item["preview"]

    # CRITICAL: Verify full body is completely absent from list response
    assert "body" not in item


def test_journal_pagination(client: TestClient):
    """Cursor-based pagination traversal for journal entries."""
    token = register_user(client, "meera.journal_pag@campus.edu", "Meera Sen")
    headers = {"Authorization": f"Bearer {token}"}

    # Insert 5 entries
    for i in range(5):
        res = client.post(
            "/v1/journal",
            json={
                "client_id": str(uuid.uuid4()),
                "title": f"Entry {i}",
                "body": f"Reflections content for test entry number {i}.",
            },
            headers=headers,
        )
        assert res.status_code == 201

    # Page 1: limit 2
    p1 = client.get("/v1/journal?limit=2", headers=headers).json()
    assert len(p1["items"]) == 2
    assert p1["has_more"] is True
    assert p1["next_cursor"] is not None

    # Page 2: limit 2 with cursor
    p2 = client.get(f"/v1/journal?limit=2&cursor={p1['next_cursor']}", headers=headers).json()
    assert len(p2["items"]) == 2
    assert p2["has_more"] is True
    assert p2["next_cursor"] is not None

    # Page 3: final item
    p3 = client.get(f"/v1/journal?limit=2&cursor={p2['next_cursor']}", headers=headers).json()
    assert len(p3["items"]) == 1
    assert p3["has_more"] is False


def test_journal_two_account_isolation(client: TestClient):
    """
    CRITICAL RULE 13 & 404-NOT-403:
    User B must NEVER be able to read, update, or delete User A's journal entry.
    The response MUST be 404 Not Found (never 403) to prevent resource leakage.
    """
    token_a = register_user(client, "journal.user.a@campus.edu", "User A")
    token_b = register_user(client, "journal.user.b@campus.edu", "User B")

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A creates journal entry
    create_res = client.post(
        "/v1/journal",
        json={
            "client_id": str(uuid.uuid4()),
            "title": "Private Diary",
            "body": "User A deeply personal thoughts that User B must never see.",
        },
        headers=headers_a,
    )
    assert create_res.status_code == 201
    entry_id = create_res.json()["id"]

    # User B attempts to read User A's journal -> 404 Not Found
    get_res = client.get(f"/v1/journal/{entry_id}", headers=headers_b)
    assert get_res.status_code == 404, f"Expected 404 Not Found, got {get_res.status_code}"

    # User B attempts to update User A's journal -> 404 Not Found
    patch_res = client.patch(
        f"/v1/journal/{entry_id}",
        json={"title": "Hacked", "body": "Tampered body"},
        headers=headers_b,
    )
    assert patch_res.status_code == 404, f"Expected 404 Not Found, got {patch_res.status_code}"

    # User B attempts to delete User A's journal -> 404 Not Found
    del_res = client.delete(f"/v1/journal/{entry_id}", headers=headers_b)
    assert del_res.status_code == 404, f"Expected 404 Not Found, got {del_res.status_code}"

    # User B list contains 0 journal entries
    list_b = client.get("/v1/journal", headers=headers_b).json()
    assert len(list_b["items"]) == 0

    # User A can still retrieve the journal intact
    get_a = client.get(f"/v1/journal/{entry_id}", headers=headers_a)
    assert get_a.status_code == 200
    assert "User A deeply personal thoughts" in get_a.json()["body"]


def test_journal_cascade_delete(client: TestClient, db_session: Session):
    """When a user is deleted, their journal entries are deleted by ON DELETE CASCADE."""
    token = register_user(client, "cascade.journal@campus.edu", "Cascade Journal User")
    headers = {"Authorization": f"Bearer {token}"}

    create_res = client.post(
        "/v1/journal",
        json={
            "client_id": str(uuid.uuid4()),
            "title": "Cascade Diary",
            "body": "Will be cascade deleted.",
        },
        headers=headers,
    )
    assert create_res.status_code == 201
    entry_id = uuid.UUID(create_res.json()["id"])

    # Locate user and delete from db_session
    user = db_session.scalars(select(User).where(User.email == "cascade.journal@campus.edu")).first()
    assert user is not None
    db_session.delete(user)
    db_session.commit()

    # Verify journal entry is cascade deleted
    entry = db_session.scalars(select(JournalEntry).where(JournalEntry.id == entry_id)).first()
    assert entry is None
