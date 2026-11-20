import uuid
from datetime import datetime, timezone
from sqlalchemy.orm import Session

from app.models.account_event import AccountEvent, AccountEventType
from app.models.user import User


def test_account_event_creation_and_cascade(db_session: Session):
    user = User(
        email=f"event_test_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="hashed_pw",
        display_name="Event Tester",
        role="student",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    event = AccountEvent(
        user_id=user.id,
        event_type=AccountEventType.PASSWORD_CHANGED,
    )
    db_session.add(event)
    db_session.commit()
    db_session.refresh(event)

    assert event.id is not None
    assert event.user_id == user.id
    assert event.event_type == AccountEventType.PASSWORD_CHANGED
    assert event.created_at is not None

    # Test cascade delete
    db_session.delete(user)
    db_session.commit()

    deleted_event = db_session.query(AccountEvent).filter_by(id=event.id).first()
    assert deleted_event is None


def test_doctor_summary_generated_event(db_session: Session):
    """Verify that doctor_summary_generated is a valid AccountEventType and persists correctly."""
    user = User(
        email=f"summary_event_{uuid.uuid4().hex[:8]}@example.com",
        password_hash="hashed_pw",
        display_name="Summary Tester",
        role="student",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)

    from app.repositories.account_event_repository import AccountEventRepository
    repo = AccountEventRepository(db_session)
    event = repo.record_event(user.id, AccountEventType.DOCTOR_SUMMARY_GENERATED)

    assert event.id is not None
    assert event.user_id == user.id
    assert event.event_type == AccountEventType.DOCTOR_SUMMARY_GENERATED
    assert event.event_type.value == "doctor_summary_generated"

    events = repo.list_events(user.id)
    assert len(events) == 1
    assert events[0].event_type == AccountEventType.DOCTOR_SUMMARY_GENERATED
