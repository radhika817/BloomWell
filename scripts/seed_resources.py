#!/usr/bin/env python3
"""
Seed script for HelpHub verified resources and period product access points.
Loads fictional demo entries from docs/seed/resources.demo.json and
real verified entries from docs/seed/resources.json.
Enforces domain publishing and verification rules idempotently.
"""
import json
import os
import sys
import uuid
from datetime import date
from pathlib import Path

# Ensure backend/ is in sys.path
repo_root = Path(__file__).resolve().parent.parent
backend_dir = repo_root / "backend"
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

from sqlalchemy import select
from app.db.session import SessionLocal
from app.models.resource import Resource, VerificationStatus


def validate_resource_entry(item: dict) -> None:
    """Validate resource entry against domain publishing constraints."""
    name = item.get("name")
    is_published = item.get("is_published", False)
    is_demo = item.get("is_demo", False)
    verification_status = item.get("verification_status")
    source_url = item.get("source_url")
    last_verified_at = item.get("last_verified_at")
    available_24x7 = item.get("available_24x7")

    if is_published and not is_demo:
        if verification_status != VerificationStatus.VERIFIED.value:
            raise ValueError(f"Resource '{name}' is published and non-demo, but verification_status is '{verification_status}' (must be 'verified').")
        if not source_url:
            raise ValueError(f"Resource '{name}' is published and non-demo, but source_url is missing.")
        if not last_verified_at:
            raise ValueError(f"Resource '{name}' is published and non-demo, but last_verified_at date is missing.")

    if available_24x7 is True:
        if verification_status != VerificationStatus.VERIFIED.value or not source_url:
            raise ValueError(f"Resource '{name}' specifies available_24x7=True, but is not verified with a source_url.")


def seed_resources(
    demo_path: Path = repo_root / "docs/seed/resources.demo.json",
    real_path: Path = repo_root / "docs/seed/resources.json",
    db_session=None,
) -> tuple[int, int]:
    """
    Load and upsert resources from demo and real seed files.
    Returns (created_count, updated_count).
    """
    entries = []
    if demo_path.exists():
        with open(demo_path, "r", encoding="utf-8") as f:
            demo_items = json.load(f)
            for item in demo_items:
                item["is_demo"] = True
            entries.extend(demo_items)

    if real_path.exists():
        with open(real_path, "r", encoding="utf-8") as f:
            real_items = json.load(f)
            for item in real_items:
                item["is_demo"] = False
            entries.extend(real_items)

    session = db_session or SessionLocal()
    close_session = db_session is None

    created_count = 0
    updated_count = 0

    try:
        for item in entries:
            validate_resource_entry(item)

            stmt = select(Resource).where(Resource.name == item["name"])
            existing = session.scalars(stmt).first()

            last_ver_date = (
                date.fromisoformat(item["last_verified_at"])
                if item.get("last_verified_at")
                else None
            )

            if existing:
                existing.category = item["category"]
                existing.description = item["description"]
                existing.phone = item.get("phone")
                existing.email = item.get("email")
                existing.website_url = item.get("website_url")
                existing.address = item.get("address")
                existing.city = item.get("city")
                existing.hours_text = item.get("hours_text")
                existing.available_24x7 = item.get("available_24x7")
                existing.languages = item.get("languages", [])
                existing.cost = item.get("cost", "unknown")
                existing.product_details = item.get("product_details")
                existing.source_url = item.get("source_url")
                existing.verification_status = item.get("verification_status", "unverified")
                existing.last_verified_at = last_ver_date
                existing.verified_by = item.get("verified_by")
                existing.is_published = item.get("is_published", False)
                existing.is_demo = item.get("is_demo", False)
                updated_count += 1
            else:
                new_resource = Resource(
                    id=uuid.uuid4(),
                    name=item["name"],
                    category=item["category"],
                    description=item["description"],
                    phone=item.get("phone"),
                    email=item.get("email"),
                    website_url=item.get("website_url"),
                    address=item.get("address"),
                    city=item.get("city"),
                    hours_text=item.get("hours_text"),
                    available_24x7=item.get("available_24x7"),
                    languages=item.get("languages", []),
                    cost=item.get("cost", "unknown"),
                    product_details=item.get("product_details"),
                    source_url=item.get("source_url"),
                    verification_status=item.get("verification_status", "unverified"),
                    last_verified_at=last_ver_date,
                    verified_by=item.get("verified_by"),
                    is_published=item.get("is_published", False),
                    is_demo=item.get("is_demo", False),
                )
                session.add(new_resource)
                created_count += 1

        session.commit()
    finally:
        if close_session:
            session.close()

    return created_count, updated_count


def main():
    print("Seeding HelpHub resources...")
    created, updated = seed_resources()
    print(f"HelpHub seeding complete: {created} created, {updated} updated.")


if __name__ == "__main__":
    main()
