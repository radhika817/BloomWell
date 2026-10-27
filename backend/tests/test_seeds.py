import json
import sys
from pathlib import Path
import pytest
from sqlalchemy.orm import Session

repo_root = Path(__file__).resolve().parent.parent.parent
if str(repo_root) not in sys.path:
    sys.path.insert(0, str(repo_root))

from scripts.seed_resources import seed_resources, validate_resource_entry
from scripts.seed_education import EDUCATION_ARTICLES, seed_education
from app.models.resource import Resource
from app.models.education import EducationResource

FORBIDDEN_WORDS = [
    "diagnose",
    "cure",
    "treat",
    "ovulation",
    "fertile",
    "pregnancy",
    "abnormal",
    "irregular",
    "dosage",
]


def test_seed_resources_idempotency_and_validation(db_session: Session, tmp_path: Path):
    # 1. Test validation rejects published real entry without verification
    invalid_real = {
        "name": "Invalid Real Clinic",
        "category": "counseling",
        "description": "Clinic.",
        "is_published": True,
        "is_demo": False,
        "verification_status": "unverified",
    }
    with pytest.raises(ValueError, match="is published and non-demo, but verification_status"):
        validate_resource_entry(invalid_real)

    # 2. Test validation rejects 24x7 without source
    invalid_247 = {
        "name": "Invalid 24x7 Helpline",
        "category": "helpline",
        "description": "Helpline.",
        "available_24x7": True,
        "verification_status": "unverified",
    }
    with pytest.raises(ValueError, match="available_24x7=True"):
        validate_resource_entry(invalid_247)

    # 3. Create sample valid demo file
    demo_file = tmp_path / "resources.demo.json"
    demo_file.write_text(
        json.dumps([
            {
                "name": "Test Demo Dispenser (Demo)",
                "category": "period_products",
                "description": "Demo dispenser.",
                "city": "Pune",
                "cost": "free",
                "product_details": {"items": ["pads"]},
                "verification_status": "verified",
                "source_url": "https://example.org/dispenser",
                "last_verified_at": "2026-10-01",
                "is_published": True,
                "is_demo": True,
            }
        ]),
        encoding="utf-8",
    )
    real_file = tmp_path / "resources.json"
    real_file.write_text("[]", encoding="utf-8")

    # Run 1: creates 1
    created, updated = seed_resources(demo_path=demo_file, real_path=real_file, db_session=db_session)
    assert created == 1
    assert updated == 0

    # Run 2: updates 1 (idempotent)
    created2, updated2 = seed_resources(demo_path=demo_file, real_path=real_file, db_session=db_session)
    assert created2 == 0
    assert updated2 == 1


def test_seed_education_vocabulary_and_guardrails():
    """
    CRITICAL CLINICAL & VOCABULARY GUARDRAIL TEST:
    Assert all educational articles contain NONE of the forbidden clinical words:
    diagnose, cure, treat, ovulation, fertile, pregnancy, abnormal, irregular, dosage.
    Assert all articles start as draft, with 'BloomWell team draft', and contain a doctor talk note.
    """
    assert len(EDUCATION_ARTICLES) == 8, f"Expected 8 articles, found {len(EDUCATION_ARTICLES)}"

    for article in EDUCATION_ARTICLES:
        slug = article["slug"]
        combined_text = f"{article['title']} {article['summary']} {article['body']}".lower()

        # Vocabulary scan
        for word in FORBIDDEN_WORDS:
            assert word not in combined_text, (
                f"Forbidden word '{word}' found in article '{slug}'!"
            )

        # Review status and source
        assert article["review_status"] == "draft", f"Article '{slug}' must start as 'draft'!"
        assert article["source_name"] == "BloomWell team draft", f"Article '{slug}' source must be team draft!"

        # Doctor or nurse note requirement
        body_lower = article["body"].lower()
        assert "doctor or nurse" in body_lower or "healthcare professional" in body_lower or "healthcare provider" in body_lower, (
            f"Article '{slug}' must include a 'when to talk to a doctor or nurse' note!"
        )


def test_seed_education_idempotency(db_session: Session):
    """Verify education seed runs idempotently without duplicating records."""
    created1, updated1 = seed_education(db_session=db_session)
    assert created1 == 8
    assert updated1 == 0

    # Running a second time updates the 8 items and creates 0
    created2, updated2 = seed_education(db_session=db_session)
    assert created2 == 0
    assert updated2 == 8
