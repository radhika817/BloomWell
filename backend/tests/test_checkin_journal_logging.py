import io
import logging
import uuid
from datetime import date
from fastapi.testclient import TestClient

from app.core.logging import RedactingJsonFormatter, SensitiveDataFilter


def test_zero_logging_on_checkin_and_journal_endpoints(client: TestClient):
    """
    CRITICAL RULE 4:
    Zero-Logging of Sensitive Data: Never log or print journal text, symptom notes,
    cycle dates, mood scores, or tokens.
    Verify end-to-end that real HTTP requests handling check-ins and journal entries
    never emit notes, tags, journal body, or titles into logs.
    """
    # Attach a capturing StreamHandler with RedactingJsonFormatter & SensitiveDataFilter
    log_stream = io.StringIO()
    handler = logging.StreamHandler(log_stream)
    handler.setFormatter(RedactingJsonFormatter("%(levelname)s %(message)s"))
    handler.addFilter(SensitiveDataFilter())

    root_logger = logging.getLogger()
    api_logger = logging.getLogger("bloomwell.api")
    root_logger.addHandler(handler)
    api_logger.addHandler(handler)

    try:
        # Register test user
        reg_resp = client.post(
            "/v1/auth/register",
            json={
                "email": "zero.logging@campus.edu",
                "password": "Password123!",
                "display_name": "Logging Test User",
                "timezone": "Asia/Kolkata",
            },
        )
        assert reg_resp.status_code == 201
        token = reg_resp.json()["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        sentinel_notes = "CONFIDENTIAL_SENTINEL_NOTES_CHECKIN_998877"
        sentinel_tag = "secret-tag-9988"
        sentinel_title = "CONFIDENTIAL_SENTINEL_TITLE_665544"
        sentinel_body = "CONFIDENTIAL_SENTINEL_BODY_JOURNAL_112233_HIGHLY_PRIVATE"

        # 1. Create check-in
        res_checkin = client.post(
            "/v1/checkins",
            json={
                "client_id": str(uuid.uuid4()),
                "local_date": str(date.today()),
                "mood_score": 4,
                "stress_score": 2,
                "energy_score": 4,
                "mood_label": "calm",
                "tags": [sentinel_tag],
                "notes": sentinel_notes,
            },
            headers=headers,
        )
        assert res_checkin.status_code == 201

        # 2. Create journal entry
        res_journal = client.post(
            "/v1/journal",
            json={
                "client_id": str(uuid.uuid4()),
                "title": sentinel_title,
                "body": sentinel_body,
            },
            headers=headers,
        )
        assert res_journal.status_code == 201

        # 3. Retrieve journal list
        res_list = client.get("/v1/journal", headers=headers)
        assert res_list.status_code == 200

        captured = log_stream.getvalue()

        # CRITICAL ASSERTIONS: Sentinels must NEVER appear in captured logs
        assert sentinel_notes not in captured, "Sensitive check-in notes leaked into logs!"
        assert sentinel_tag not in captured, "Sensitive check-in tags leaked into logs!"
        assert sentinel_title not in captured, "Sensitive journal title leaked into logs!"
        assert sentinel_body not in captured, "Sensitive journal body leaked into logs!"

    finally:
        root_logger.removeHandler(handler)
        api_logger.removeHandler(handler)


def test_zero_logging_on_study_planner_and_insights(client: TestClient):
    """
    CRITICAL RULE (AGENTS.md Rule 7 & Section 6):
    Zero-Logging of Sensitive Data: Never log scores, dates, reason codes,
    plan content or counts tied to a user.
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
        reg_resp = client.post(
            "/v1/auth/register",
            json={
                "email": "planner.logging@campus.edu",
                "password": "Password123!",
                "display_name": "Planner Log User",
                "timezone": "UTC",
            },
        )
        assert reg_resp.status_code == 201
        token = reg_resp.json()["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        # 1. Generate plan
        week_str = "2026-11-09"
        res_plan = client.post(
            "/v1/study-plans/generate",
            json={"week_start": week_str, "replace": True},
            headers=headers,
        )
        assert res_plan.status_code == 201
        item_id = res_plan.json()["items"][0]["id"]

        # 2. Patch item
        res_patch = client.patch(
            f"/v1/study-plans/items/{item_id}",
            json={"status": "edited", "suggested_load": "focus"},
            headers=headers,
        )
        assert res_patch.status_code == 200

        # 3. Call insights
        res_ins = client.get(f"/v1/insights/weekly?week_start={week_str}", headers=headers)
        assert res_ins.status_code == 200

        captured = log_stream.getvalue()

        # Check that plan reason codes, suggested loads, or scores never leak in logs
        assert "NOT_ENOUGH_HISTORY" not in captured
        assert "WEEKDAY_ENERGY_HIGHER" not in captured
        assert "CYCLE_RECORDED_PERIOD_LOW_ENERGY" not in captured
        assert "KEEP_OPTION_PRESERVED" not in captured

    finally:
        root_logger.removeHandler(handler)
        api_logger.removeHandler(handler)

