import uuid
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.education import (
    EducationCategory,
    EducationLanguage,
    EducationResource,
    ReviewStatus,
)


def _get_auth_headers(client: TestClient) -> dict:
    resp = client.post(
        "/v1/auth/register",
        json={
            "email": f"edu_user_{uuid.uuid4().hex[:8]}@example.com",
            "password": "Password123!",
            "display_name": "Edu Tester",
            "timezone": "UTC",
        },
    )
    token = resp.json()["tokens"]["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_education_unauthenticated_returns_401(client: TestClient):
    resp = client.get("/v1/education")
    assert resp.status_code == 401
    resp_slug = client.get("/v1/education/understanding-cycles")
    assert resp_slug.status_code == 401


def test_education_list_and_language_fallback(client: TestClient, db_session: Session):
    headers = _get_auth_headers(client)

    # 1. English-only article
    art1_en = EducationResource(
        slug="hygiene-guidelines",
        title="Everyday Hygiene Basics",
        category=EducationCategory.HYGIENE.value,
        language=EducationLanguage.EN.value,
        summary="A gentle guide to daily hygiene routines.",
        body="Plain text guidelines on self-care and hygiene.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        reviewed_at=date(2026, 10, 1),
        is_published=True,
    )
    # 2. English & Marathi article
    art2_en = EducationResource(
        slug="when-to-seek-care",
        title="When to Consult a Health Professional",
        category=EducationCategory.WHEN_TO_SEEK_CARE.value,
        language=EducationLanguage.EN.value,
        summary="Understanding when professional evaluation helps.",
        body="Clear signs to schedule an appointment with a doctor or nurse.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        reviewed_at=date(2026, 10, 1),
        is_published=True,
    )
    art2_mr = EducationResource(
        slug="when-to-seek-care",
        title="आरोग्य तज्ज्ञांचा सल्ला कधी घ्यावा",
        category=EducationCategory.WHEN_TO_SEEK_CARE.value,
        language=EducationLanguage.MR.value,
        summary="डॉक्टरांचा सल्ला कधी घ्यावा याबद्दल माहिती.",
        body="मराठी मजकूर: आरोग्य सेवेबद्दल स्पष्ट मार्गदर्शक तत्त्वे.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        reviewed_at=date(2026, 10, 1),
        is_published=True,
    )
    db_session.add_all([art1_en, art2_en, art2_mr])
    db_session.commit()

    # Request with language=mr
    resp = client.get("/v1/education?language=mr", headers=headers)
    assert resp.status_code == 200
    items = resp.json()["items"]
    assert len(items) == 2

    by_slug = {it["slug"]: it for it in items}
    # hygiene-guidelines fell back to English
    assert by_slug["hygiene-guidelines"]["language"] == "en"
    assert by_slug["hygiene-guidelines"]["title"] == "Everyday Hygiene Basics"

    # when-to-seek-care returned Marathi version
    assert by_slug["when-to-seek-care"]["language"] == "mr"
    assert by_slug["when-to-seek-care"]["title"] == "आरोग्य तज्ज्ञांचा सल्ला कधी घ्यावा"

    # Fetching slug in mr returns Marathi
    resp_slug_mr = client.get("/v1/education/when-to-seek-care?language=mr", headers=headers)
    assert resp_slug_mr.status_code == 200
    assert resp_slug_mr.json()["language"] == "mr"

    # Fetching hygiene-guidelines in mr falls back to English
    resp_fallback = client.get("/v1/education/hygiene-guidelines?language=mr", headers=headers)
    assert resp_fallback.status_code == 200
    assert resp_fallback.json()["language"] == "en"


def test_education_production_mode_hides_drafts(client: TestClient, db_session: Session, monkeypatch):
    headers = _get_auth_headers(client)

    draft_art = EducationResource(
        slug="draft-emotional-wellness",
        title="Emotional Well-being Reflection",
        category=EducationCategory.EMOTIONAL_WELLBEING.value,
        language=EducationLanguage.EN.value,
        summary="A draft guide to personal reflections.",
        body="Draft content under review.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.DRAFT.value,
        is_published=True,
    )
    reviewed_art = EducationResource(
        slug="reviewed-basics",
        title="Menstrual Basics Reviewed",
        category=EducationCategory.PERIODS_BASICS.value,
        language=EducationLanguage.EN.value,
        summary="Reviewed educational guide.",
        body="Reviewed plain text content.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        reviewed_at=date.today(),
        is_published=True,
    )
    db_session.add_all([draft_art, reviewed_art])
    db_session.commit()

    # In dev mode (ALLOW_DRAFT_CONTENT=True), draft is visible
    resp_dev = client.get(f"/v1/education/{draft_art.slug}", headers=headers)
    assert resp_dev.status_code == 200

    # In prod mode (ALLOW_DRAFT_CONTENT=False), draft is hidden (404)
    monkeypatch.setattr(settings, "ALLOW_DRAFT_CONTENT", False)

    resp_prod_draft = client.get(f"/v1/education/{draft_art.slug}", headers=headers)
    assert resp_prod_draft.status_code == 404

    resp_prod_rev = client.get(f"/v1/education/{reviewed_art.slug}", headers=headers)
    assert resp_prod_rev.status_code == 200

    list_prod = client.get("/v1/education", headers=headers)
    assert list_prod.status_code == 200
    list_slugs = [it["slug"] for it in list_prod.json()["items"]]
    assert draft_art.slug not in list_slugs
    assert reviewed_art.slug in list_slugs
