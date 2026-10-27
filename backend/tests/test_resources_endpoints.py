import uuid
from datetime import date, timedelta
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.resource import (
    CostType,
    Resource,
    ResourceCategory,
    VerificationStatus,
)


def _get_auth_headers(client: TestClient) -> dict:
    resp = client.post(
        "/v1/auth/register",
        json={
            "email": f"res_user_{uuid.uuid4().hex[:8]}@example.com",
            "password": "Password123!",
            "display_name": "Resource Tester",
            "timezone": "Asia/Kolkata",
        },
    )
    token = resp.json()["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_resources_unauthenticated_returns_401(client: TestClient):
    resp = client.get("/v1/resources")
    assert resp.status_code == 401
    resp_sup = client.get("/v1/resources/support")
    assert resp_sup.status_code == 401


def test_resources_list_and_filters(client: TestClient, db_session: Session):
    headers = _get_auth_headers(client)
    today = date.today()

    # Seed resources
    r1 = Resource(
        name="Campus Mental Health Clinic (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Confidential counseling for students.",
        city="Pune",
        languages=["en", "hi"],
        cost=CostType.FREE.value,
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/clinic",
        last_verified_at=today - timedelta(days=30),
        is_published=True,
        is_demo=True,
    )
    r2 = Resource(
        name="Main Hostel Period Products Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Free pads dispenser in lobby.",
        city="Pune",
        languages=["en"],
        cost=CostType.FREE.value,
        product_details={"items": ["pads"], "free_or_paid": "free", "how_to_access": "Press button"},
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/hostel",
        last_verified_at=today - timedelta(days=10),
        is_published=True,
        is_demo=True,
    )
    r3 = Resource(
        name="Mumbai Workshop Series (Demo)",
        category=ResourceCategory.WORKSHOP.value,
        description="Menstrual awareness workshop.",
        city="Mumbai",
        languages=["mr"],
        cost=CostType.PAID.value,
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/workshop",
        last_verified_at=today - timedelta(days=5),
        is_published=True,
        is_demo=True,
    )
    db_session.add_all([r1, r2, r3])
    db_session.commit()

    # 1. List all
    res = client.get("/v1/resources", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert len(data["items"]) >= 3

    # 2. Filter by category
    res_pads = client.get("/v1/resources?category=period_products", headers=headers)
    assert res_pads.status_code == 200
    items_pads = res_pads.json()["items"]
    assert len(items_pads) == 1
    assert items_pads[0]["name"] == "Main Hostel Period Products Dispenser (Demo)"
    assert items_pads[0]["product_details"]["items"] == ["pads"]

    # 3. Filter by city
    res_mumbai = client.get("/v1/resources?city=Mumbai", headers=headers)
    assert res_mumbai.status_code == 200
    assert len(res_mumbai.json()["items"]) == 1
    assert res_mumbai.json()["items"][0]["city"] == "Mumbai"

    # 4. Search q
    res_q = client.get("/v1/resources?q=confidential", headers=headers)
    assert res_q.status_code == 200
    assert len(res_q.json()["items"]) == 1
    assert res_q.json()["items"][0]["id"] == str(r1.id)

    # 5. Free only
    res_free = client.get("/v1/resources?free_only=true", headers=headers)
    assert res_free.status_code == 200
    for it in res_free.json()["items"]:
        assert it["cost"] == "free"


def test_resources_staleness_and_outdated_exclusion(client: TestClient, db_session: Session):
    headers = _get_auth_headers(client)
    today = date.today()

    # 1. 179 days old -> not stale
    r_fresh = Resource(
        name="Fresh Counseling (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Fresh clinic.",
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/fresh",
        last_verified_at=today - timedelta(days=179),
        is_published=True,
        is_demo=True,
    )
    # 2. Exactly 180 days old -> is_stale True
    r_exact_stale = Resource(
        name="Exact 180 Days Stale (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Stale clinic at threshold.",
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/exact",
        last_verified_at=today - timedelta(days=180),
        is_published=True,
        is_demo=True,
    )
    # 3. 181 days old -> is_stale True
    r_older_stale = Resource(
        name="181 Days Stale (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Older clinic past threshold.",
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/older",
        last_verified_at=today - timedelta(days=181),
        is_published=True,
        is_demo=True,
    )
    # 4. Marked outdated -> is_stale True
    r_outdated = Resource(
        name="Marked Outdated Helpline (Demo)",
        category=ResourceCategory.HELPLINE.value,
        description="Outdated listing.",
        available_24x7=False,
        verification_status=VerificationStatus.OUTDATED.value,
        source_url="https://example.org/outdated",
        last_verified_at=today - timedelta(days=10),
        is_published=True,
        is_demo=True,
    )
    db_session.add_all([r_fresh, r_exact_stale, r_older_stale, r_outdated])
    db_session.commit()

    # By default, outdated is excluded from listing
    res = client.get("/v1/resources", headers=headers)
    assert res.status_code == 200
    items_by_id = {it["id"]: it for it in res.json()["items"]}
    assert str(r_fresh.id) in items_by_id
    assert items_by_id[str(r_fresh.id)]["is_stale"] is False

    assert str(r_exact_stale.id) in items_by_id
    assert items_by_id[str(r_exact_stale.id)]["is_stale"] is True

    assert str(r_older_stale.id) in items_by_id
    assert items_by_id[str(r_older_stale.id)]["is_stale"] is True

    assert str(r_outdated.id) not in items_by_id

    # With include_outdated=true, outdated is returned and flagged is_stale True
    res_outdated = client.get("/v1/resources?include_outdated=true", headers=headers)
    assert res_outdated.status_code == 200
    items_outdated_map = {it["id"]: it for it in res_outdated.json()["items"]}
    assert str(r_outdated.id) in items_outdated_map
    assert items_outdated_map[str(r_outdated.id)]["is_stale"] is True
    assert items_outdated_map[str(r_outdated.id)]["verification_status"] == "outdated"


def test_resources_support_endpoint(client: TestClient, db_session: Session):
    headers = _get_auth_headers(client)
    today = date.today()

    # 1. Verified 24x7 non-stale helpline
    r_247 = Resource(
        name="National Tele-Mental Support (Demo)",
        category=ResourceCategory.HELPLINE.value,
        description="24x7 verified helpline.",
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/tele",
        last_verified_at=today - timedelta(days=20),
        is_published=True,
        is_demo=True,
    )
    # 2. Verified regular hours non-stale counseling
    r_reg = Resource(
        name="Campus Counseling Cell (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Daytime campus counseling.",
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/cell",
        last_verified_at=today - timedelta(days=5),
        is_published=True,
        is_demo=True,
    )
    # 3. Verified period products (NOT counseling/helpline)
    r_dispenser = Resource(
        name="Dormitory Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Free pad dispenser.",
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/dorm",
        last_verified_at=today - timedelta(days=5),
        is_published=True,
        is_demo=True,
    )
    # 4. Outdated helpline (stale)
    r_stale_help = Resource(
        name="Old Helpline (Demo)",
        category=ResourceCategory.HELPLINE.value,
        description="Stale helpline.",
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/oldhelp",
        last_verified_at=today - timedelta(days=200),
        is_published=True,
        is_demo=True,
    )
    db_session.add_all([r_247, r_reg, r_dispenser, r_stale_help])
    db_session.commit()

    resp = client.get("/v1/resources/support", headers=headers)
    assert resp.status_code == 200
    support_items = resp.json()

    # Must contain r_247 and r_reg, but NOT r_dispenser (wrong category) and NOT r_stale_help (stale)
    support_ids = [it["id"] for it in support_items]
    assert str(r_247.id) in support_ids
    assert str(r_reg.id) in support_ids
    assert str(r_dispenser.id) not in support_ids
    assert str(r_stale_help.id) not in support_ids

    # Deterministic order: 24x7 first
    idx_247 = support_ids.index(str(r_247.id))
    idx_reg = support_ids.index(str(r_reg.id))
    assert idx_247 < idx_reg


def test_production_mode_hides_demo_resources(client: TestClient, db_session: Session, monkeypatch):
    headers = _get_auth_headers(client)

    demo_res = Resource(
        name="Demo Only Clinic (Demo)",
        category=ResourceCategory.HEALTH_CLINIC.value,
        description="Fictional clinic.",
        is_published=True,
        is_demo=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/demo",
        last_verified_at=date.today(),
    )
    db_session.add(demo_res)
    db_session.commit()

    # In development mode, it is returned
    resp_dev = client.get(f"/v1/resources/{demo_res.id}", headers=headers)
    assert resp_dev.status_code == 200

    # In production mode (ALLOW_DEMO_RESOURCES = False), it is hidden
    monkeypatch.setattr(settings, "ALLOW_DEMO_RESOURCES", False)
    resp_prod = client.get(f"/v1/resources/{demo_res.id}", headers=headers)
    assert resp_prod.status_code == 404

    resp_list = client.get("/v1/resources", headers=headers)
    assert resp_list.status_code == 200
    list_ids = [it["id"] for it in resp_list.json()["items"]]
    assert str(demo_res.id) not in list_ids
