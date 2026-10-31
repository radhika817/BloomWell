import uuid
from datetime import date
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.academic_event import AcademicEvent
from app.models.activity import Activity, UserActivityLog
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.journal import JournalEntry
from app.models.user import User
from app.services.export_service import ExportLimitExceededException, export_registry


def test_export_registry_coverage_and_serialization(db_session: Session):
    user = User(
        email=f"export_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="secret_hashed",
        display_name="Export Subject",
        role="student",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    # Add records to checkin, journal, academic event, cycle log
    checkin = MoodCheckin(
        user_id=user.id,
        client_id=uuid.uuid4(),
        local_date=date.today(),
        mood_score=4,
        stress_score=2,
        energy_score=4,
        notes="Testing export notes",
    )
    journal = JournalEntry(
        user_id=user.id,
        client_id=uuid.uuid4(),
        title="Export Journal",
        body="Secret thoughts should be exported for the user only.",
    )
    db_session.add_all([checkin, journal])
    db_session.commit()

    export_doc = export_registry.export_all(db_session, user.id)

    assert "metadata" in export_doc
    assert export_doc["metadata"]["total_records"] >= 3
    assert export_doc["profile"]["display_name"] == "Export Subject"
    assert "password_hash" not in export_doc["profile"]
    assert "password" not in str(export_doc)
    assert len(export_doc["checkins"]) == 1
    assert export_doc["checkins"][0]["notes"] == "Testing export notes"
    assert len(export_doc["journal"]) == 1
    assert export_doc["journal"][0]["body"] == "Secret thoughts should be exported for the user only."


def test_export_record_cap_raises_413(db_session: Session, monkeypatch):
    user = User(
        email=f"cap_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="secret_hashed",
        display_name="Cap Subject",
        role="student",
    )
    db_session.add(user)
    db_session.commit()

    # Artificially set EXPORT_MAX_RECORDS to 1
    monkeypatch.setattr(settings, "EXPORT_MAX_RECORDS", 1)

    journal = JournalEntry(
        user_id=user.id,
        client_id=uuid.uuid4(),
        title="J1",
        body="Text",
    )
    db_session.add(journal)
    db_session.commit()

    try:
        export_registry.export_all(db_session, user.id)
        assert False, "Should have raised ExportLimitExceededException"
    except ExportLimitExceededException as e:
        assert e.max_records == 1
        assert e.count > 1
