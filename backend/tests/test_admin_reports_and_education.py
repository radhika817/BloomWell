import uuid
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models.user import User
from app.models.resource import (
    ReportReason,
    ReportStatus,
    Resource,
    ResourceCategory,
    ResourceReport,
    VerificationStatus,
)
from app.models.education import (
    EducationCategory,
    EducationLanguage,
    EducationResource,
    ReviewStatus,
)


def _create_user_and_token(db: Session, role: str = "student", email: str = None) -> tuple[User, str]:
    mail = email or f"{role}_{uuid.uuid4().hex[:8]}@example.com"
    user = User(
        email=mail,
        password_hash="hashed_pw",
        display_name=f"User {role}",
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.role)
    return user, token


def test_admin_reports_and_education_forbidden_for_students(client: TestClient, db_session: Session):
    _, student_token = _create_user_and_token(db_session, role="student")
    headers = {"Authorization": f"Bearer {student_token}"}

    assert client.get("/v1/admin/resource-reports", headers=headers).status_code == 403
    assert client.get("/v1/admin/education", headers=headers).status_code == 403
    assert client.post("/v1/admin/education", json={}, headers=headers).status_code == 403


def test_admin_reports_excludes_reporter_identity(client: TestClient, db_session: Session):
    """
    CRITICAL PRIVACY TEST:
    Admin reports list must NEVER include reporter_id or reporter identity anywhere in the JSON response!
    """
    reporter_email = "secret.reporter.99@campus.edu"
    reporter, _ = _create_user_and_token(db_session, role="student", email=reporter_email)
    _, admin_token = _create_user_and_token(db_session, role="resource_admin")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    res = Resource(
        name="Hostel Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Demo pad dispenser.",
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/hostel",
        last_verified_at=date.today(),
        is_published=True,
        is_demo=True,
    )
    db_session.add(res)
    db_session.commit()

    report = ResourceReport(
        resource_id=res.id,
        reporter_id=reporter.id,
        reason=ReportReason.OUT_OF_ORDER.value,
        note="Coin slot jammed.",
        status=ReportStatus.OPEN.value,
    )
    db_session.add(report)
    db_session.commit()

    # Admin fetches reports
    resp = client.get("/v1/admin/resource-reports", headers=admin_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["items"]) >= 1

    # Recursive check: assert reporter_id or reporter_email or reporter's UUID never appears
    def check_no_reporter_leak(obj):
        if isinstance(obj, dict):
            for k, v in obj.items():
                assert "reporter" not in k.lower(), f"Leaked reporter key: {k}"
                assert str(reporter.id) != str(v), f"Leaked reporter UUID in field: {k}"
                check_no_reporter_leak(v)
        elif isinstance(obj, list):
            for item in obj:
                check_no_reporter_leak(item)
        elif isinstance(obj, str):
            assert reporter_email not in obj, "Leaked reporter email in string value!"
            assert str(reporter.id) not in obj, "Leaked reporter UUID in string value!"

    check_no_reporter_leak(data)

    # Admin resolves report
    resp_patch = client.patch(
        f"/v1/admin/resource-reports/{report.id}",
        json={"status": "resolved", "resolved_note": "Technician cleared jammed coin slot."},
        headers=admin_headers,
    )
    assert resp_patch.status_code == 200
    assert resp_patch.json()["status"] == "resolved"
    assert resp_patch.json()["resolved_note"] == "Technician cleared jammed coin slot."
    check_no_reporter_leak(resp_patch.json())


def test_admin_education_crud(client: TestClient, db_session: Session):
    _, admin_token = _create_user_and_token(db_session, role="resource_admin")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 1. Create education article
    resp_create = client.post(
        "/v1/admin/education",
        json={
            "slug": "cramps-and-comfort",
            "title": "Understanding Cramps and Comfort",
            "category": "common_symptoms",
            "language": "en",
            "summary": "Gentle, non-diagnostic guidance on everyday menstrual cramps.",
            "body": "Paragraph 1: What mild cramps feel like.\n\nParagraph 2: Everyday comfort suggestions like a warm water bottle.",
            "source_name": "BloomWell team draft",
            "review_status": "draft",
            "is_published": True,
        },
        headers=admin_headers,
    )
    assert resp_create.status_code == 201
    edu_id = resp_create.json()["id"]
    assert resp_create.json()["review_status"] == "draft"

    # 2. Update education article (mark reviewed)
    resp_update = client.patch(
        f"/v1/admin/education/{edu_id}",
        json={
            "review_status": "reviewed",
            "reviewed_at": str(date.today()),
            "source_name": "Reviewed by Nurse Maya",
        },
        headers=admin_headers,
    )
    assert resp_update.status_code == 200
    assert resp_update.json()["review_status"] == "reviewed"
    assert resp_update.json()["source_name"] == "Reviewed by Nurse Maya"

    # 3. List admin education
    resp_list = client.get("/v1/admin/education", headers=admin_headers)
    assert resp_list.status_code == 200
    ids = [it["id"] for it in resp_list.json()["items"]]
    assert edu_id in ids

    # 4. Delete education article
    resp_del = client.delete(f"/v1/admin/education/{edu_id}", headers=admin_headers)
    assert resp_del.status_code == 204
