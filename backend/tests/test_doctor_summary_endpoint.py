"""Tests for POST /v1/me/doctor-summary endpoint."""

import os
from datetime import date, timedelta
import io
import uuid
from fastapi.testclient import TestClient
import pypdf
import pytest
from sqlalchemy.orm import Session

from app.api.v1.me import doctor_summary_limiter
from app.core.config import settings
from app.core.security import create_access_token, create_step_up_token, hash_password
from app.models.account_event import AccountEvent, AccountEventType
from app.models.preference import UserPreference
from app.models.user import User
from app.repositories.cycle_repository import CycleRepository
from app.repositories.symptom_repository import SymptomRepository


def _create_user_with_token(
    db: Session,
    cycle_tracking: bool = True,
    email_prefix: str = "doc_endpoint_user",
):
    user = User(
        email=f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com",
        password_hash=hash_password("valid-password-123"),
        display_name="Summary Tester",
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


def test_doctor_summary_endpoint_requires_auth(client: TestClient):
    """Verify endpoint rejects requests without Authorization header."""
    res = client.post("/v1/me/doctor-summary", json={"from_date": "2026-01-01", "to_date": "2026-01-30"})
    assert res.status_code == 401


def test_doctor_summary_endpoint_requires_step_up(client: TestClient, db_session: Session):
    """Verify endpoint rejects requests without X-Reauth-Token header."""
    user, access_token, _ = _create_user_with_token(db_session)
    res = client.post(
        "/v1/me/doctor-summary",
        headers={"Authorization": f"Bearer {access_token}"},
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 401
    assert "Step-up re-authentication required" in res.text


def test_doctor_summary_endpoint_rejects_cross_user_reauth_token(
    client: TestClient, db_session: Session
):
    """Verify endpoint rejects step-up token belonging to a different user."""
    user_a, access_token_a, _ = _create_user_with_token(db_session, email_prefix="user_a")
    user_b, _, step_up_token_b = _create_user_with_token(db_session, email_prefix="user_b")

    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token_a}",
            "X-Reauth-Token": step_up_token_b,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 401
    assert "does not match the authenticated user" in res.text


def test_doctor_summary_endpoint_cycle_tracking_disabled(
    client: TestClient, db_session: Session
):
    """Verify endpoint returns 403 cycle_tracking_disabled when user has not enabled tracking."""
    user, access_token, step_up_token = _create_user_with_token(
        db_session, cycle_tracking=False
    )
    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 403
    data = res.json()
    assert data["code"] == "cycle_tracking_disabled"
    assert "requires cycle tracking to be enabled" in data["message"]


def test_doctor_summary_endpoint_success_and_headers(
    client: TestClient, db_session: Session
):
    """
    Verify successful PDF generation:
      - Valid response headers (attachment, no-store, pragma no-cache).
      - Response body is parseable PDF.
      - doctor_summary_generated audit event recorded.
      - Zero temporary files left on disk.
    """
    user, access_token, step_up_token = _create_user_with_token(db_session)

    # Seed cycle and symptom data
    cycle_repo = CycleRepository(db_session)
    symptom_repo = SymptomRepository(db_session)
    cycle_repo.create_cycle_log(user.id, date(2026, 1, 1), date(2026, 1, 5))
    symptom_repo.create_symptom_log(
        user.id, date(2026, 1, 2), "cramps", 3, notes="Mild morning discomfort"
    )

    # Snapshot files before request
    files_before = set(os.listdir("/tmp"))

    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
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
            "language": "en",
        },
    )

    # Snapshot files after request
    files_after = set(os.listdir("/tmp"))
    # Strictly zero new files created on disk
    new_tmp_files = files_after - files_before
    assert not new_tmp_files, f"Disk leak detected: {new_tmp_files}"

    assert res.status_code == 200
    assert res.headers["content-type"] == "application/pdf"
    assert res.headers["content-disposition"] == 'attachment; filename="bloomwell-summary.pdf"'
    assert res.headers["cache-control"] == "no-store"
    assert res.headers["pragma"] == "no-cache"

    pdf_bytes = res.content
    assert pdf_bytes.startswith(b"%PDF")

    reader = pypdf.PdfReader(io.BytesIO(pdf_bytes))
    assert len(reader.pages) >= 1
    page_text = reader.pages[0].extract_text()
    assert "Personal health notes summary" in page_text
    assert "Recorded by me in BloomWell" in page_text
    assert "Logged symptoms" in page_text

    # Verify audit event recorded
    events = (
        db_session.query(AccountEvent)
        .filter(
            AccountEvent.user_id == user.id,
            AccountEvent.event_type == AccountEventType.DOCTOR_SUMMARY_GENERATED,
        )
        .all()
    )
    assert len(events) == 1


def test_doctor_summary_endpoint_rate_limit(client: TestClient, db_session: Session):
    """Verify exceeding DOCTOR_SUMMARY_DAILY_LIMIT returns 429 Too Many Requests."""
    user, access_token, step_up_token = _create_user_with_token(db_session)
    doctor_summary_limiter._records[str(user.id)] = []

    # Make allowed requests up to limit
    for _ in range(settings.DOCTOR_SUMMARY_DAILY_LIMIT):
        res = client.post(
            "/v1/me/doctor-summary",
            headers={
                "Authorization": f"Bearer {access_token}",
                "X-Reauth-Token": step_up_token,
            },
            json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
        )
        assert res.status_code == 200

    # Next request must be rate limited
    res_limited = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res_limited.status_code == 429
    assert "Retry-After" in res_limited.headers


def test_doctor_summary_endpoint_symptom_cap_413(
    client: TestClient, db_session: Session, monkeypatch
):
    """Verify collector's SummaryTooLargeError is propagated as 413 summary_too_large."""
    user, access_token, step_up_token = _create_user_with_token(db_session)

    from app.repositories.symptom_repository import SymptomRepository

    monkeypatch.setattr(
        SymptomRepository,
        "count_symptoms_in_range",
        lambda self, user_id, from_date, to_date: settings.DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS + 1,
    )

    res = client.post(
        "/v1/me/doctor-summary",
        headers={
            "Authorization": f"Bearer {access_token}",
            "X-Reauth-Token": step_up_token,
        },
        json={"from_date": "2026-01-01", "to_date": "2026-01-30"},
    )
    assert res.status_code == 413
    data = res.json()
    assert data["code"] == "summary_too_large"
    assert "narrower" in data["message"].lower() or "too many" in data["message"].lower()
