import io
import logging
import uuid
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.logging import RedactingJsonFormatter, SensitiveDataFilter
from app.core.security import create_access_token
from app.models.user import User
from app.models.resource import (
    Resource,
    ResourceCategory,
    VerificationStatus,
)


def _create_user(db: Session, role: str) -> tuple[User, str]:
    user = User(
        email=f"{role}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="hashed_pw",
        display_name=f"User {role}",
        role=role,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_access_token(user.id, user.role)
    return user, token


def test_zero_logging_on_helphub_reports_and_searches(client: TestClient, db_session: Session):
    """
    CRITICAL RULE (AGENTS.md Rule 7 & Section 6):
    Never log report notes, resolved notes, reporter ids, or resource searches q.
    Verify end-to-end with real requests using unique sentinel strings.
    """
    log_stream = io.StringIO()
    handler = logging.StreamHandler(log_stream)
    handler.setFormatter(RedactingJsonFormatter("%(levelname)s %(message)s"))
    handler.addFilter(SensitiveDataFilter())

    root_logger = logging.getLogger()
    api_logger = logging.getLogger("bloomwell.api")
    root_logger.addHandler(handler)
    api_logger.addHandler(handler)

    try:
        student, student_token = _create_user(db_session, "student")
        admin, admin_token = _create_user(db_session, "resource_admin")
        student_headers = {"Authorization": f"Bearer {student_token}"}
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        res = Resource(
            name="Campus Sanitary Dispenser (Demo)",
            category=ResourceCategory.PERIOD_PRODUCTS.value,
            description="Lobby dispenser.",
            available_24x7=True,
            verification_status=VerificationStatus.VERIFIED.value,
            source_url="https://example.org/res",
            last_verified_at=date.today(),
            is_published=True,
            is_demo=True,
        )
        db_session.add(res)
        db_session.commit()

        sentinel_report_note = "CONFIDENTIAL_SENTINEL_REPORT_NOTE_9988776655"
        sentinel_resolved_note = "CONFIDENTIAL_SENTINEL_RESOLVED_NOTE_4433221100"
        sentinel_search_q = "CONFIDENTIAL_SENTINEL_SEARCH_QUERY_ABCXYZ"

        # 1. Student creates report with confidential note
        res_report = client.post(
            f"/v1/resources/{res.id}/report",
            json={"reason": "out_of_order", "note": sentinel_report_note},
            headers=student_headers,
        )
        assert res_report.status_code == 201
        report_id = res_report.json()["id"]

        # 2. Admin resolves report with confidential resolved note
        res_resolve = client.patch(
            f"/v1/admin/resource-reports/{report_id}",
            json={"status": "resolved", "resolved_note": sentinel_resolved_note},
            headers=admin_headers,
        )
        assert res_resolve.status_code == 200

        # 3. User performs search with sensitive query
        res_search = client.get(
            f"/v1/resources?q={sentinel_search_q}",
            headers=student_headers,
        )
        assert res_search.status_code == 200

        # Also emit a log record with dict keys to verify RedactingJsonFormatter
        api_logger.info(
            "Audit event",
            extra={
                "note": sentinel_report_note,
                "resolved_note": sentinel_resolved_note,
                "q": sentinel_search_q,
                "reporter_id": str(student.id),
            },
        )

        captured = log_stream.getvalue()

        # CRITICAL ASSERTIONS: None of the sentinels may leak into logs
        assert sentinel_report_note not in captured, "Sensitive report note leaked into logs!"
        assert sentinel_resolved_note not in captured, "Sensitive resolved note leaked into logs!"
        assert sentinel_search_q not in captured, "Sensitive search query leaked into logs!"
        assert str(student.id) not in captured, "Reporter ID leaked into logs!"

    finally:
        root_logger.removeHandler(handler)
        api_logger.removeHandler(handler)


def test_error_responses_do_not_echo_submitted_text(client: TestClient, db_session: Session):
    """
    CRITICAL PRIVACY RULE:
    Error responses must not echo submitted text in validation failure bodies.
    """
    _, student_token = _create_user(db_session, "student")
    headers = {"Authorization": f"Bearer {student_token}"}

    sentinel_invalid_input = "CONFIDENTIAL_INVALID_TEXT_TO_NOT_ECHO_778899"

    # Send invalid report payload containing sensitive sentinel text
    resp = client.post(
        f"/v1/resources/{uuid.uuid4()}/report",
        json={
            "reason": "invalid_reason_code_123",
            "note": sentinel_invalid_input,
        },
        headers=headers,
    )
    assert resp.status_code == 422
    err_body = resp.text
    assert sentinel_invalid_input not in err_body, "Validation error response echoed sensitive input text!"


def test_admin_token_cannot_access_other_users_private_data(client: TestClient, db_session: Session):
    """
    CRITICAL ISOLATION RULE:
    An admin token cannot access ANY private-data endpoint belonging to another user.
    Admin responses contain no private fields.
    """
    user_a, token_a = _create_user(db_session, "student")
    admin, admin_token = _create_user(db_session, "resource_admin")

    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_admin = {"Authorization": f"Bearer {admin_token}"}

    # User A creates check-in
    res_checkin = client.post(
        "/v1/checkins",
        json={
            "client_id": str(uuid.uuid4()),
            "local_date": str(date.today()),
            "mood_score": 4,
            "stress_score": 2,
            "energy_score": 4,
            "mood_label": "calm",
            "notes": "User A private wellness note.",
        },
        headers=headers_a,
    )
    assert res_checkin.status_code == 201

    # User A creates journal entry
    res_journal = client.post(
        "/v1/journal",
        json={
            "client_id": str(uuid.uuid4()),
            "title": "User A Journal",
            "body": "User A private journal reflection.",
        },
        headers=headers_a,
    )
    assert res_journal.status_code == 201
    journal_id = res_journal.json()["id"]

    # 1. Admin accesses check-ins list -> must be empty (admin has no check-ins)
    admin_checkins = client.get("/v1/checkins", headers=headers_admin)
    assert admin_checkins.status_code == 200
    assert len(admin_checkins.json()["items"]) == 0

    # 2. Admin accesses journal list -> must be empty
    admin_journal = client.get("/v1/journal", headers=headers_admin)
    assert admin_journal.status_code == 200
    assert len(admin_journal.json()["items"]) == 0

    # 3. Admin attempts to fetch User A's journal entry by ID -> returns 404
    admin_get_entry = client.get(f"/v1/journal/{journal_id}", headers=headers_admin)
    assert admin_get_entry.status_code == 404

    # 4. Admin accesses study planner -> no access to User A's plan
    admin_plan = client.get("/v1/study-plans/current", headers=headers_admin)
    assert admin_plan.status_code == 404


def test_privacy_center_zero_logging_and_no_device_metadata(client: TestClient, db_session: Session):
    """
    ZERO-LOGGING REDACTION & SENSITIVE DATA PRIVACY TEST:
    Assert that sensitive sentinels (passwords, step-up tokens, export texts, notes)
    never appear in logs, error responses, or the account_events table.
    Assert account_events and exports contain NO IP address, device name, or location fields.
    """
    import io
    from app.core.security import create_access_token, create_step_up_token, hash_password
    from app.models.account_event import AccountEvent, AccountEventType
    from app.models.checkin import MoodCheckin
    from app.models.journal import JournalEntry
    from app.services.export_service import export_registry

    log_stream = io.StringIO()
    handler = logging.StreamHandler(log_stream)
    handler.setFormatter(RedactingJsonFormatter("%(levelname)s %(message)s"))
    handler.addFilter(SensitiveDataFilter())

    root_logger = logging.getLogger()
    api_logger = logging.getLogger("bloomwell.api")
    root_logger.addHandler(handler)
    api_logger.addHandler(handler)

    try:
        user, token = _create_user(db_session, "student")
        step_up_token = create_step_up_token(user.id)
        headers = {
            "Authorization": f"Bearer {token}",
            "X-Reauth-Token": step_up_token,
        }

        sentinel_journal = f"SECRET_JOURNAL_{uuid.uuid4().hex}"
        sentinel_note = f"SECRET_NOTE_{uuid.uuid4().hex}"
        sentinel_pw = "SuperSecretPassword123!"

        # Seed private data with sentinels
        j = JournalEntry(
            user_id=user.id,
            client_id=uuid.uuid4(),
            title="Secret Title",
            body=sentinel_journal,
        )
        c = MoodCheckin(
            user_id=user.id,
            client_id=uuid.uuid4(),
            local_date=date.today(),
            mood_score=5,
            stress_score=1,
            energy_score=5,
            notes=sentinel_note,
        )
        db_session.add_all([j, c])
        db_session.commit()

        # 1. Trigger export
        res_exp = client.get("/v1/me/export", headers=headers)
        assert res_exp.status_code == 200

        # 2. Trigger invalid input error on password change to ensure error body doesn't echo submitted password
        res_err = client.post(
            "/v1/me/password",
            json={"current_password": sentinel_pw, "new_password": "short"},
            headers=headers,
        )
        assert res_err.status_code in (401, 422)
        assert sentinel_pw not in res_err.text

        # 3. Trigger reauth
        res_reauth = client.post(
            "/v1/me/reauth",
            json={"password": "DummyNonExistentPassword!"},
            headers=headers,
        )
        assert "DummyNonExistentPassword" not in res_reauth.text

        # 4. Check log output for sentinels
        logs_text = log_stream.getvalue()
        assert sentinel_journal not in logs_text
        assert sentinel_note not in logs_text
        assert sentinel_pw not in logs_text
        assert step_up_token not in logs_text

        # 5. Inspect account_events table: NO IP, device, or payload columns exist
        from sqlalchemy import inspect
        mapper = inspect(AccountEvent)
        column_names = [col.key for col in mapper.columns]
        assert "ip_address" not in column_names
        assert "ip" not in column_names
        assert "device" not in column_names
        assert "device_info" not in column_names
        assert "payload" not in column_names
        assert set(column_names) == {"id", "user_id", "event_type", "created_at"}

        # Check export content has no IP or device fields
        export_text = res_exp.text
        assert "ip_address" not in export_text.lower()
        assert "device_info" not in export_text.lower()
        assert "user_agent" not in export_text.lower()
    finally:
        root_logger.removeHandler(handler)
        api_logger.removeHandler(handler)
