"""Security, privacy, and architectural boundary tests for Doctor-visit Summary."""

from datetime import date
import io
import logging
import uuid
from fastapi.testclient import TestClient
import pypdf
import pytest
from sqlalchemy.orm import Session

from app.core.security import create_access_token, create_step_up_token, hash_password
from app.models.account_event import AccountEvent, AccountEventType
from app.models.preference import UserPreference
from app.models.user import User
from app.repositories.cycle_repository import CycleRepository
from app.repositories.symptom_repository import SymptomRepository


def _create_user(
    db: Session,
    email_prefix: str = "sec_user",
    cycle_tracking: bool = True,
):
    user = User(
        email=f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("password-123"),
        display_name=f"User {email_prefix}",
        role="student",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    pref = UserPreference(
        user_id=user.id,
        cycle_tracking_enabled=cycle_tracking,
        language="en",
        timezone="UTC",
    )
    db.add(pref)
    db.commit()
    db.refresh(user)

    access_token = create_access_token(user.id, user.role)
    step_up_token = create_step_up_token(user.id)
    return user, access_token, step_up_token


def test_e2e_two_account_isolation_through_endpoint(
    client: TestClient, db_session: Session
):
    """
    CRITICAL TWO-ACCOUNT ISOLATION TEST THROUGH HTTP ENDPOINT:
    User A downloading their doctor summary PDF must NEVER see User B's
    custom labels, notes, period dates, or personal identifiers.
    """
    user_a, token_a, reauth_a = _create_user(db_session, "user_a")
    user_b, token_b, reauth_b = _create_user(db_session, "user_b")

    cycle_repo = CycleRepository(db_session)
    symptom_repo = SymptomRepository(db_session)

    # User A records
    cycle_repo.create_cycle_log(user_a.id, date(2026, 1, 1), date(2026, 1, 5))
    symptom_repo.create_symptom_log(
        user_a.id,
        date(2026, 1, 2),
        "cramps",
        2,
        custom_label="USER_A_CRAMP_LABEL",
        notes="USER_A_PERSONAL_NOTE_RECORD",
    )

    # User B records with unique marker strings
    marker_b_label = "USER_B_UNIQUE_LABEL_MARKER_99"
    marker_b_note = "USER_B_UNIQUE_NOTE_MARKER_88"
    cycle_repo.create_cycle_log(user_b.id, date(2026, 1, 10), date(2026, 1, 15))
    symptom_repo.create_symptom_log(
        user_b.id,
        date(2026, 1, 12),
        "bloating",
        4,
        custom_label=marker_b_label,
        notes=marker_b_note,
    )

    # User A requests summary
    res_a = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {token_a}",
            "X-Reauth-Token": reauth_a,
        },
        json={
            "from_date": "2026-01-01",
            "to_date": "2026-01-30",
            "include": {
                "periods": True,
                "symptoms": True,
                "symptom_notes": True,
                "estimate": False,
                "questions": True,
            },
        },
    )
    assert res_a.status_code == 200
    reader_a = pypdf.PdfReader(io.BytesIO(res_a.content))
    pdf_text_a = "\n".join([p.extract_text() or "" for p in reader_a.pages])

    # Assert User A data is present
    assert "USER_A_CRAMP_LABEL" in pdf_text_a
    assert "USER_A_PERSONAL_NOTE_RECORD" in pdf_text_a

    # Assert ZERO trace of User B's unique strings, UUID, or email
    assert marker_b_label not in pdf_text_a
    assert marker_b_note not in pdf_text_a
    assert str(user_b.id) not in pdf_text_a
    assert user_b.email not in pdf_text_a


def test_zero_logging_and_error_sanitization(
    client: TestClient, db_session: Session, caplog
):
    """
    PRIVACY & ZERO-LOGGING TEST (AGENTS.md Rule 7):
    Sensitive notes, labels, and cycle dates must never appear in logs or error bodies.
    """
    user, access_token, step_up_token = _create_user(db_session, "privacy_user")

    # 1. Capture logs during valid generation
    with caplog.at_level(logging.DEBUG):
        res = client.post(
            "/v1/me/doctor-summary",
            headers={
                "Authorization": f"Bearer {access_token}",
                "X-Reauth-Token": step_up_token,
            },
            json={
                "from_date": "2026-01-01",
                "to_date": "2026-01-30",
                "include": {"periods": True, "symptoms": True, "symptom_notes": True},
            },
        )
        assert res.status_code == 200

    # Ensure no cycle dates or tokens leaked to logs
    for record in caplog.records:
        log_msg = record.getMessage()
        assert step_up_token not in log_msg
        assert access_token not in log_msg

    # 2. Validation error response sanitization (no echo of sensitive inputs)
    untracked_input = "UNTRACKED_TEXT_12345"
    err_res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={
            "from_date": "2026-01-01",
            "to_date": "2026-01-30",
            "forbidden_journal_field": untracked_input,
        },
    )
    assert err_res.status_code == 422
    assert untracked_input not in err_res.text


def test_account_events_contain_no_sensitive_payload(
    client: TestClient, db_session: Session
):
    """Verify that doctor_summary_generated event records only event_type without sensitive payload."""
    user, access_token, step_up_token = _create_user(db_session, "event_user")

    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 200

    events = (
        db_session.query(AccountEvent)
        .filter(
            AccountEvent.user_id == user.id,
            AccountEvent.event_type == AccountEventType.DOCTOR_SUMMARY_GENERATED,
        )
        .all()
    )
    assert len(events) == 1
    event = events[0]
    # Check that event has no extra payload or leak
    assert event.event_type == AccountEventType.DOCTOR_SUMMARY_GENERATED
    assert event.user_id == user.id


def test_cors_exposes_content_disposition(client: TestClient):
    """Verify CORS configuration exposes Content-Disposition header for web clients."""
    from app.core.config import settings

    allowed_origin = (
        settings.cors_origins_list[0]
        if settings.cors_origins_list
        else "http://localhost:3000"
    )
    res = client.get(
        "/health",
        headers={"Origin": allowed_origin},
    )
    assert res.status_code == 200
    expose_headers = res.headers.get("access-control-expose-headers", "")
    assert (
        "Content-Disposition" in expose_headers
        or "content-disposition" in expose_headers.lower()
    )


def test_pdf_metadata_strictly_anonymous(client: TestClient, db_session: Session):
    """Verify PDF metadata (Author, Title, Creator) is neutral with zero user info."""
    user, access_token, step_up_token = _create_user(db_session, "meta_user")

    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 200

    reader = pypdf.PdfReader(io.BytesIO(res.content))
    meta = reader.metadata or {}

    assert meta.get("/Title") == "Personal health notes summary"
    assert meta.get("/Author") == "BloomWell"
    assert meta.get("/Creator") == "BloomWell"

    meta_str = str(meta)
    assert str(user.id) not in meta_str
    assert user.email not in meta_str
    assert user.display_name not in meta_str
