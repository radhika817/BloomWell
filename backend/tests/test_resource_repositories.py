import uuid
from datetime import date, datetime, timedelta, timezone
import pytest
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.resource import (
    CostType,
    ReportReason,
    ReportStatus,
    Resource,
    ResourceCategory,
    VerificationStatus,
)
from app.models.education import (
    EducationCategory,
    EducationLanguage,
    EducationResource,
    ReviewStatus,
)
from app.repositories.resource_repository import ResourceRepository
from app.repositories.resource_report_repository import (
    ReportExistsError,
    ResourceReportRepository,
)
from app.repositories.education_repository import EducationRepository


def test_resource_repository_filtering_and_support_endpoints(db_session: Session):
    repo = ResourceRepository(db_session)
    today = date(2026, 10, 27)

    # 1. Non-stale verified helpline
    res1 = Resource(
        name="Demo Counseling Support (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Demo counseling clinic.",
        city="Pune",
        languages=["en", "hi"],
        cost=CostType.FREE.value,
        available_24x7=True,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/counseling",
        last_verified_at=today - timedelta(days=30),
        is_published=True,
        is_demo=True,
    )
    # 2. Outdated helpline
    res2 = Resource(
        name="Outdated Helpline (Demo)",
        category=ResourceCategory.HELPLINE.value,
        description="Old helpline listing.",
        city="Mumbai",
        languages=["en"],
        cost=CostType.FREE.value,
        available_24x7=False,
        verification_status=VerificationStatus.OUTDATED.value,
        source_url="https://example.org/old",
        last_verified_at=today - timedelta(days=200),
        is_published=True,
        is_demo=True,
    )
    # 3. Period products access point
    res3 = Resource(
        name="Student Union Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Free sanitary napkins dispenser.",
        city="Pune",
        languages=["en", "mr"],
        cost=CostType.FREE.value,
        product_details={"items": ["pads"], "free_or_paid": "free"},
        available_24x7=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://example.org/dispenser",
        last_verified_at=today - timedelta(days=10),
        is_published=True,
        is_demo=True,
    )
    repo.create(res1)
    repo.create(res2)
    repo.create(res3)

    # Test list_resources: default excludes outdated
    items, _ = repo.list_resources(include_outdated=False)
    ids = [i.id for i in items]
    assert res1.id in ids
    assert res3.id in ids
    assert res2.id not in ids

    # Test include_outdated=True
    items_all, _ = repo.list_resources(include_outdated=True)
    ids_all = [i.id for i in items_all]
    assert res2.id in ids_all

    # Test city filter
    pune_items, _ = repo.list_resources(city="Pune")
    for item in pune_items:
        assert item.city == "Pune"

    # Test category filter
    pad_items, _ = repo.list_resources(category=ResourceCategory.PERIOD_PRODUCTS.value)
    assert len(pad_items) == 1
    assert pad_items[0].id == res3.id

    # Test support resources: only published, verified, non-stale counseling/helpline
    support_items = repo.get_support_resources(stale_threshold_date=today - timedelta(days=180))
    assert len(support_items) == 1
    assert support_items[0].id == res1.id


def test_resource_report_repository_owner_scoping(db_session: Session):
    u1 = User(email="user1@example.com", password_hash="h1", role="student")
    u2 = User(email="user2@example.com", password_hash="h2", role="student")
    db_session.add_all([u1, u2])
    db_session.flush()

    res = Resource(
        name="Library Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Demo pad dispenser.",
        is_published=True,
        is_demo=True,
    )
    db_session.add(res)
    db_session.flush()

    repo = ResourceReportRepository(db_session)

    # User 1 creates report
    rep1 = repo.create_report(
        user_id=u1.id,
        resource_id=res.id,
        reason=ReportReason.OUT_OF_ORDER.value,
        note="Dispenser jammed.",
    )
    assert rep1.reporter_id == u1.id

    # Duplicate open report by User 1 raises ReportExistsError
    with pytest.raises(ReportExistsError):
        repo.create_report(
            user_id=u1.id,
            resource_id=res.id,
            reason=ReportReason.OUT_OF_ORDER.value,
        )

    # User 2 can create an open report for the same resource
    rep2 = repo.create_report(
        user_id=u2.id,
        resource_id=res.id,
        reason=ReportReason.OUT_OF_ORDER.value,
    )
    assert rep2.reporter_id == u2.id

    # Isolation check: User 1 only sees their own reports
    u1_reports, _ = repo.get_user_reports(user_id=u1.id)
    assert len(u1_reports) == 1
    assert u1_reports[0].id == rep1.id

    u2_reports, _ = repo.get_user_reports(user_id=u2.id)
    assert len(u2_reports) == 1
    assert u2_reports[0].id == rep2.id

    # Daily count
    since = datetime.now(timezone.utc) - timedelta(days=1)
    assert repo.count_daily_reports_for_user(u1.id, since) == 1


def test_education_repository_fallback_to_english(db_session: Session):
    repo = EducationRepository(db_session)

    # Article 1 in English only
    edu_en = EducationResource(
        slug="hygiene-basics",
        title="Hygiene Basics",
        category=EducationCategory.HYGIENE.value,
        language=EducationLanguage.EN.value,
        summary="Basic hygiene care.",
        body="Plain text body.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        is_published=True,
    )
    # Article 2 in English and Marathi
    edu_en2 = EducationResource(
        slug="when-to-see-doctor",
        title="When to Seek Care",
        category=EducationCategory.WHEN_TO_SEEK_CARE.value,
        language=EducationLanguage.EN.value,
        summary="Guidelines on when to consult a doctor.",
        body="Body in English.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        is_published=True,
    )
    edu_mr2 = EducationResource(
        slug="when-to-see-doctor",
        title="डॉक्टरांचा सल्ला कधी घ्यावा",
        category=EducationCategory.WHEN_TO_SEEK_CARE.value,
        language=EducationLanguage.MR.value,
        summary="वैद्यकीय सल्ला मार्गदर्शक.",
        body="मराठी मजकूर.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.REVIEWED.value,
        is_published=True,
    )
    repo.create(edu_en)
    repo.create(edu_en2)
    repo.create(edu_mr2)

    # Fetching 'hygiene-basics' in mr falls back to English
    item1 = repo.get_by_slug("hygiene-basics", language="mr")
    assert item1 is not None
    assert item1.language == "en"

    # Fetching 'when-to-see-doctor' in mr returns Marathi
    item2 = repo.get_by_slug("when-to-see-doctor", language="mr")
    assert item2 is not None
    assert item2.language == "mr"

    # Listing with language mr returns 2 distinct articles, one in mr, one fallen back to en
    items, _ = repo.list_education(language="mr")
    slugs = {it.slug for it in items}
    assert slugs == {"hygiene-basics", "when-to-see-doctor"}
    lang_by_slug = {it.slug: it.language for it in items}
    assert lang_by_slug["hygiene-basics"] == "en"
    assert lang_by_slug["when-to-see-doctor"] == "mr"
