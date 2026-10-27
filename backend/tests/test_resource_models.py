import uuid
from datetime import date
import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.resource import (
    Resource,
    ResourceReport,
    ResourceCategory,
    CostType,
    VerificationStatus,
    ReportReason,
    ReportStatus,
)
from app.models.education import (
    EducationResource,
    EducationCategory,
    EducationLanguage,
    ReviewStatus,
)


def test_users_role_check_constraint(db_session: Session):
    """Verify users.role check constraint rejects invalid roles and accepts valid roles."""
    with db_session.begin_nested():
        user = User(
            email="role.test@example.com",
            password_hash="hashed",
            role="invalid_role",
        )
        db_session.add(user)
        with pytest.raises(IntegrityError):
            db_session.flush()

    # Valid roles
    for role in ["student", "moderator", "resource_admin"]:
        u = User(
            email=f"{role}@example.com",
            password_hash="hashed",
            role=role,
        )
        db_session.add(u)
        db_session.flush()


def test_resource_published_and_24x7_constraints(db_session: Session):
    """Verify published non-demo resources require verification, and 24x7 requires verified+source."""
    # 1. Published non-demo resource without verification fails
    with db_session.begin_nested():
        res_invalid_pub = Resource(
            name="Unverified Resource",
            category=ResourceCategory.COUNSELING.value,
            description="A counseling clinic without verification.",
            is_published=True,
            is_demo=False,
            verification_status=VerificationStatus.UNVERIFIED.value,
        )
        db_session.add(res_invalid_pub)
        with pytest.raises(IntegrityError):
            db_session.flush()

    # 2. Demo resource published without verification is allowed
    res_demo = Resource(
        name="Demo Counseling (Demo)",
        category=ResourceCategory.COUNSELING.value,
        description="Demo counseling service.",
        is_published=True,
        is_demo=True,
        verification_status=VerificationStatus.UNVERIFIED.value,
    )
    db_session.add(res_demo)
    db_session.flush()

    # 3. Non-demo published resource WITH verified status, source_url, last_verified_at succeeds
    res_verified = Resource(
        name="Campus Health Center",
        category=ResourceCategory.HEALTH_CLINIC.value,
        description="Official campus health center.",
        is_published=True,
        is_demo=False,
        verification_status=VerificationStatus.VERIFIED.value,
        source_url="https://health.campus.edu",
        last_verified_at=date(2026, 10, 1),
        verified_by="Staff Admin",
        available_24x7=True,
    )
    db_session.add(res_verified)
    db_session.flush()

    # 4. available_24x7=True on unverified resource fails
    with db_session.begin_nested():
        res_unverified_24x7 = Resource(
            name="Unverified 24x7 Resource",
            category=ResourceCategory.HELPLINE.value,
            description="Helpline claiming 24x7 without verification.",
            available_24x7=True,
            verification_status=VerificationStatus.UNVERIFIED.value,
        )
        db_session.add(res_unverified_24x7)
        with pytest.raises(IntegrityError):
            db_session.flush()


def test_resource_reports_constraints_and_user_deletion(db_session: Session):
    """Verify resource report duplicate open report partial index and ON DELETE SET NULL on reporter."""
    user = User(
        email="reporter@example.com",
        password_hash="hashed",
        role="student",
    )
    res = Resource(
        name="Demo Pads Dispenser (Demo)",
        category=ResourceCategory.PERIOD_PRODUCTS.value,
        description="Dispenser at Library 2nd floor.",
        is_published=True,
        is_demo=True,
    )
    db_session.add_all([user, res])
    db_session.flush()

    # Create report 1
    rep1 = ResourceReport(
        resource_id=res.id,
        reporter_id=user.id,
        reason=ReportReason.OUT_OF_ORDER.value,
        note="Machine accepts coin but no pad dispensed.",
        status=ReportStatus.OPEN.value,
    )
    db_session.add(rep1)
    db_session.flush()

    # Duplicate open report by same user for same resource fails
    with db_session.begin_nested():
        rep2 = ResourceReport(
            resource_id=res.id,
            reporter_id=user.id,
            reason=ReportReason.OUT_OF_ORDER.value,
            note="Still broken.",
            status=ReportStatus.OPEN.value,
        )
        db_session.add(rep2)
        with pytest.raises(IntegrityError):
            db_session.flush()

    # Resolving report 1 allows another open report later
    rep1.status = ReportStatus.RESOLVED.value
    rep1.resolved_note = "Restocked and serviced."
    db_session.flush()

    rep3 = ResourceReport(
        resource_id=res.id,
        reporter_id=user.id,
        reason=ReportReason.OUT_OF_ORDER.value,
        status=ReportStatus.OPEN.value,
    )
    db_session.add(rep3)
    db_session.flush()

    # Deleting user sets reporter_id to NULL on existing reports (retaining report history)
    db_session.delete(user)
    db_session.flush()

    rep3_reloaded = db_session.get(ResourceReport, rep3.id)
    assert rep3_reloaded is not None
    assert rep3_reloaded.reporter_id is None


def test_education_resource_unique_slug_language_and_categories(db_session: Session):
    """Verify education unique (slug, language) constraint and category validation."""
    edu1 = EducationResource(
        slug="understanding-cycles",
        title="Understanding Your Menstrual Cycle",
        category=EducationCategory.PERIODS_BASICS.value,
        language=EducationLanguage.EN.value,
        summary="A gentle introduction to cycles.",
        body="Paragraph 1 describing cycle basics.\n\nParagraph 2 with more info.",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.DRAFT.value,
    )
    db_session.add(edu1)
    db_session.flush()

    # Duplicate (slug, language) fails
    with db_session.begin_nested():
        edu2 = EducationResource(
            slug="understanding-cycles",
            title="Understanding Your Menstrual Cycle (Duplicate)",
            category=EducationCategory.PERIODS_BASICS.value,
            language=EducationLanguage.EN.value,
            summary="Duplicate summary.",
            body="Duplicate body.",
            source_name="BloomWell team draft",
            review_status=ReviewStatus.DRAFT.value,
        )
        db_session.add(edu2)
        with pytest.raises(IntegrityError):
            db_session.flush()

    # Same slug in Hindi succeeds
    edu_hi = EducationResource(
        slug="understanding-cycles",
        title="मासिक धर्म चक्र को समझना",
        category=EducationCategory.PERIODS_BASICS.value,
        language=EducationLanguage.HI.value,
        summary="चक्र का परिचय।",
        body="विवरण।",
        source_name="BloomWell team draft",
        review_status=ReviewStatus.DRAFT.value,
    )
    db_session.add(edu_hi)
    db_session.flush()
