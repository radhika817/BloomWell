import uuid
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.models.resource import (
    CostType,
    ReportReason,
    Resource,
    ResourceCategory,
    VerificationStatus,
)


def _get_user_token(client: TestClient, email_prefix: str = "reporter") -> str:
    resp = client.post(
        "/v1/auth/register",
        json={
            "email": f"{email_prefix}_{uuid.uuid4().hex[:8]}@example.com",
            "password": "Password123!",
            "display_name": "Report User",
            "timezone": "UTC",
        },
    )
    return resp.json()["tokens"]["access_token"]


def test_resource_reporting_and_isolation(client: TestClient, db_session: Session):
    token_a = _get_user_token(client, "user_a")
    token_b = _get_user_token(client, "user_b")
    headers_a = {"Authorization": f"Bearer {token_a}"}
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # Seed resource
    res = Resource(
        name="Campus Dispenser 1 (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Demo sanitary dispenser in library.",
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/res",
        last_verified_at=date.today(),
        is_published=True,
        is_demo=True,
    )
    db_session.add(res)
    db_session.commit()

    # 1. Unauthenticated fails
    resp_unauth = client.post(
        f"/v1/resources/{res.id}/report",
        json={"reason": "out_of_order", "note": "Empty dispenser."},
    )
    assert resp_unauth.status_code == 401

    # 2. User A reports resource
    resp_a = client.post(
        f"/v1/resources/{res.id}/report",
        json={"reason": "out_of_order", "note": "Machine is empty."},
        headers=headers_a,
    )
    assert resp_a.status_code == 201
    data_a = resp_a.json()
    assert data_a["reason"] == "out_of_order"
    assert data_a["note"] == "Machine is empty."
    assert data_a["status"] == "open"
    assert "reporter_id" not in data_a

    # 3. Duplicate open report by User A returns 409 report_exists
    resp_dup = client.post(
        f"/v1/resources/{res.id}/report",
        json={"reason": "outdated"},
        headers=headers_a,
    )
    assert resp_dup.status_code == 409
    assert "report_exists" in resp_dup.json()["detail"]

    # 4. User B can also report the same resource
    resp_b = client.post(
        f"/v1/resources/{res.id}/report",
        json={"reason": "incorrect", "note": "Wrong floor number."},
        headers=headers_b,
    )
    assert resp_b.status_code == 201

    # 5. Reported resource is NOT auto-hidden
    check_pub = client.get(f"/v1/resources/{res.id}", headers=headers_a)
    assert check_pub.status_code == 200

    # 6. Own report listing isolation
    my_reports_a = client.get("/v1/me/resource-reports", headers=headers_a)
    assert my_reports_a.status_code == 200
    items_a = my_reports_a.json()["items"]
    assert len(items_a) == 1
    assert items_a[0]["note"] == "Machine is empty."

    my_reports_b = client.get("/v1/me/resource-reports", headers=headers_b)
    assert my_reports_b.status_code == 200
    items_b = my_reports_b.json()["items"]
    assert len(items_b) == 1
    assert items_b[0]["note"] == "Wrong floor number."


def test_resource_reporting_rate_limit(client: TestClient, db_session: Session):
    token = _get_user_token(client, "rate_limiter")
    headers = {"Authorization": f"Bearer {token}"}

    # Seed 11 resources
    resources = []
    for i in range(11):
        r = Resource(
            name=f"Resource {i} (Demo)",
            category=ResourceCategory.PERIOD_PRODUCTS.value,
            description="Access point.",
            available_24x7=False,
            verification_status=VerificationStatus.VERIFIED.value,
            source_url="https://example.org/item",
            last_verified_at=date.today(),
            is_published=True,
            is_demo=True,
        )
        resources.append(r)
    db_session.add_all(resources)
    db_session.commit()

    # First 10 reports succeed
    for i in range(10):
        resp = client.post(
            f"/v1/resources/{resources[i].id}/report",
            json={"reason": "outdated"},
            headers=headers,
        )
        assert resp.status_code == 201, f"Failed on report {i}: {resp.text}"

    # 11th report exceeds daily limit of 10 and returns 429
    resp_limit = client.post(
        f"/v1/resources/{resources[10].id}/report",
        json={"reason": "outdated"},
        headers=headers,
    )
    assert resp_limit.status_code == 429
    assert "Rate limit exceeded" in resp_limit.json()["detail"]


def test_resource_report_nonexistent_and_unknown_fields(client: TestClient):
    token = _get_user_token(client, "validation")
    headers = {"Authorization": f"Bearer {token}"}

    # Non-existent resource returns 404
    fake_id = uuid.uuid4()
    resp_404 = client.post(
        f"/v1/resources/{fake_id}/report",
        json={"reason": "outdated"},
        headers=headers,
    )
    assert resp_404.status_code == 404

    # Unknown fields rejected
    resp_unknown = client.post(
        f"/v1/resources/{fake_id}/report",
        json={"reason": "outdated", "unexpected_field": "test"},
        headers=headers,
    )
    assert resp_unknown.status_code == 422
