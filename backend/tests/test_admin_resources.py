import uuid
from datetime import date, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models.user import User
from app.models.resource import (
    CostType,
    Resource,
    ResourceCategory,
    VerificationStatus,
)


def _create_user_and_token(db: Session, role: str = "student") -> tuple[User, str]:
    user = User(
        email=f"{role}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="hashed_pw",
        display_name=f"Test {role}",
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.role)
    return user, token


def test_admin_routes_forbidden_for_student(client: TestClient, db_session: Session):
    _, student_token = _create_user_and_token(db_session, role="student")
    headers = {"Authorization": f"Bearer {student_token}"}

    # GET
    res_get = client.get("/v1/admin/resources", headers=headers)
    assert res_get.status_code == 403

    # POST
    res_post = client.post("/v1/admin/resources", json={}, headers=headers)
    assert res_post.status_code == 403

    # Unauthenticated
    res_unauth = client.get("/v1/admin/resources")
    assert res_unauth.status_code == 401


def test_admin_resource_crud_and_publishing_rules(client: TestClient, db_session: Session):
    _, admin_token = _create_user_and_token(db_session, role="resource_admin")
    headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Invalid: published, non-demo without verification
    res_inv = client.post(
        "/v1/admin/resources",
        json={
            "name": "Invalid Resource",
            "category": "counseling",
            "description": "A description.",
            "is_published": True,
            "is_demo": False,
            "verification_status": "unverified",
        },
        headers=headers,
    )
    assert res_inv.status_code == 422

    # 2. Invalid: available_24x7 without verification
    res_inv_247 = client.post(
        "/v1/admin/resources",
        json={
            "name": "Invalid 24x7",
            "category": "helpline",
            "description": "Helpline claiming 24x7.",
            "available_24x7": True,
            "verification_status": "unverified",
        },
        headers=headers,
    )
    assert res_inv_247.status_code == 422

    # 3. Valid: create demo resource
    res_demo = client.post(
        "/v1/admin/resources",
        json={
            "name": "Demo Clinic (Demo)",
            "category": "health_clinic",
            "description": "Campus health clinic demo.",
            "city": "Pune",
            "cost": "free",
            "is_published": True,
            "is_demo": True,
            "verification_status": "unverified",
        },
        headers=headers,
    )
    assert res_demo.status_code == 201
    res_id = res_demo.json()["id"]

    # 4. Update resource
    res_patch = client.patch(
        f"/v1/admin/resources/{res_id}",
        json={"description": "Updated clinic description."},
        headers=headers,
    )
    assert res_patch.status_code == 200
    assert res_patch.json()["description"] == "Updated clinic description."

    # 5. Verify workflow
    res_verify = client.post(
        f"/v1/admin/resources/{res_id}/verify",
        json={
            "source_url": "https://health.campus.edu",
            "last_verified_at": str(date.today()),
            "verified_by": "Dr. Sarah",
        },
        headers=headers,
    )
    assert res_verify.status_code == 200
    assert res_verify.json()["verification_status"] == "verified"
    assert res_verify.json()["verified_by"] == "Dr. Sarah"
    assert res_verify.json()["source_url"] == "https://health.campus.edu"

    # 6. Mark outdated workflow
    res_out = client.post(
        f"/v1/admin/resources/{res_id}/mark-outdated",
        headers=headers,
    )
    assert res_out.status_code == 200
    assert res_out.json()["verification_status"] == "outdated"

    # 7. Delete resource
    res_del = client.delete(f"/v1/admin/resources/{res_id}", headers=headers)
    assert res_del.status_code == 204


def test_admin_resources_stale_filter(client: TestClient, db_session: Session):
    _, admin_token = _create_user_and_token(db_session, role="resource_admin")
    headers = {"Authorization": f"Bearer {admin_token}"}
    today = date.today()

    # Stale resource (200 days old)
    r_stale = Resource(
        name="Stale Counseling (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Needs review.",
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/stale",
        last_verified_at=today - timedelta(days=200),
        is_published=True,
        is_demo=True,
    )
    # Fresh resource (10 days old)
    r_fresh = Resource(
        name="Fresh Counseling (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Fresh listing.",
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/fresh",
        last_verified_at=today - timedelta(days=10),
        is_published=True,
        is_demo=True,
    )
    db_session.add_all([r_stale, r_fresh])
    db_session.commit()

    resp_stale = client.get("/v1/admin/resources?stale=true", headers=headers)
    assert resp_stale.status_code == 200
    stale_ids = [it["id"] for it in resp_stale.json()["items"]]
    assert str(r_stale.id) in stale_ids
    assert str(r_fresh.id) not in stale_ids


def test_role_recheck_from_live_database(client: TestClient, db_session: Session):
    """
    CRITICAL SECURITY CHECK:
    A user whose role is demoted in the database is rejected immediately
    even if their JWT access token still contains the old role claim.
    """
    admin_user, admin_token = _create_user_and_token(db_session, role="resource_admin")
    headers = {"Authorization": f"Bearer {admin_token}"}

    # Request succeeds while user is resource_admin
    res_ok = client.get("/v1/admin/resources", headers=headers)
    assert res_ok.status_code == 200

    # Demote user in database to student
    admin_user.role = "student"
    db_session.commit()

    # Subsequent request using the SAME token must now fail with 403
    res_demoted = client.get("/v1/admin/resources", headers=headers)
    assert res_demoted.status_code == 403
