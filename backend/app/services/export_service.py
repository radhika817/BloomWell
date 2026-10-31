import uuid
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Set
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models.account_event import AccountEvent, AccountEventType
from app.models.academic_event import AcademicEvent
from app.models.activity import UserActivityLog
from app.models.checkin import MoodCheckin
from app.models.cycle import CycleLog
from app.models.journal import JournalEntry
from app.models.preference import UserPreference
from app.models.resource import ResourceReport
from app.models.study_plan import StudyPlan
from app.models.user import User

# Tables excluded from data export with written architectural justification
EXPORT_EXCLUDED: Dict[str, str] = {
    "refresh_tokens": "Opaque authentication credentials; hashed in database and never exported for security reasons.",
}


class ExportLimitExceededException(Exception):
    """Raised when the user's data records exceed EXPORT_MAX_RECORDS."""

    def __init__(self, count: int, max_records: int) -> None:
        super().__init__(
            f"Export data volume ({count} records) exceeds maximum permitted limit ({max_records} records). "
            "Please contact support for assisted archive generation."
        )
        self.count = count
        self.max_records = max_records


ExporterFunc = Callable[[Session, uuid.UUID], List[Dict[str, Any]]]


class ExportRegistry:
    """
    Extensible registry for modular user data exporters.
    Each feature module registers an exporter function that fetches
    and serializes its records strictly scoped to user_id.
    """

    def __init__(self) -> None:
        self._exporters: Dict[str, ExporterFunc] = {}
        self._table_mappings: Dict[str, str] = {}

    def register(self, section_name: str, table_name: str, exporter: ExporterFunc) -> None:
        """Register an exporter for a table and export section."""
        self._exporters[section_name] = exporter
        self._table_mappings[table_name] = section_name

    def get_registered_tables(self) -> Set[str]:
        """Return all database table names covered by the registry."""
        return set(self._table_mappings.keys())

    def export_all(self, db: Session, user_id: uuid.UUID) -> Dict[str, Any]:
        """
        Execute all registered exporters for user_id.
        Enforces EXPORT_MAX_RECORDS cap and builds export document.
        """
        user = db.scalars(select(User).where(User.id == user_id, User.deleted_at.is_(None))).first()
        if not user:
            raise ValueError("User not found.")

        profile_data = {
            "id": str(user.id),
            "display_name": user.display_name,
            "role": user.role,
            "created_at": user.created_at.isoformat() if user.created_at else None,
        }

        sections_data: Dict[str, List[Dict[str, Any]]] = {}
        counts: Dict[str, int] = {"profile": 1}
        total_records = 1

        for section_name, exporter in self._exporters.items():
            records = exporter(db, user_id)
            sections_data[section_name] = records
            counts[section_name] = len(records)
            total_records += len(records)
            if total_records > settings.EXPORT_MAX_RECORDS:
                raise ExportLimitExceededException(total_records, settings.EXPORT_MAX_RECORDS)

        metadata = {
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "schema_version": "1.0",
            "total_records": total_records,
            "counts": counts,
        }

        export_document: Dict[str, Any] = {
            "metadata": metadata,
            "profile": profile_data,
        }
        export_document.update(sections_data)
        return export_document


# Global export registry instance
export_registry = ExportRegistry()


# --- Exporter implementations ---


def _export_user_preferences(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    pref = db.scalars(select(UserPreference).where(UserPreference.user_id == user_id)).first()
    if not pref:
        return []
    return [
        {
            "timezone": pref.timezone,
            "language": pref.language,
            "reminders_enabled": pref.reminders_enabled,
            "discreet_notifications": pref.discreet_notifications,
            "ai_recommendations_enabled": pref.ai_recommendations_enabled,
            "cycle_tracking_enabled": pref.cycle_tracking_enabled,
            "cycle_tracking_consent_at": pref.cycle_tracking_consent_at.isoformat() if pref.cycle_tracking_consent_at else None,
            "journal_ai_consent_at": pref.journal_ai_consent_at.isoformat() if pref.journal_ai_consent_at else None,
            "planner_cycle_consent_at": pref.planner_cycle_consent_at.isoformat() if pref.planner_cycle_consent_at else None,
        }
    ]


def _export_checkins(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    checkins = list(db.scalars(select(MoodCheckin).where(MoodCheckin.user_id == user_id).order_by(MoodCheckin.created_at)).all())
    return [
        {
            "id": str(c.id),
            "client_id": str(c.client_id),
            "local_date": c.local_date.isoformat(),
            "mood_score": c.mood_score,
            "stress_score": c.stress_score,
            "energy_score": c.energy_score,
            "sleep_quality_score": c.sleep_quality_score,
            "mood_label": c.mood_label,
            "tags": c.tags or [],
            "notes": c.notes,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in checkins
    ]


def _export_journal(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    entries = list(db.scalars(select(JournalEntry).where(JournalEntry.user_id == user_id).order_by(JournalEntry.created_at)).all())
    return [
        {
            "id": str(j.id),
            "client_id": str(j.client_id),
            "title": j.title,
            "body": j.body,
            "created_at": j.created_at.isoformat() if j.created_at else None,
        }
        for j in entries
    ]


def _export_academic_events(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    events = list(db.scalars(select(AcademicEvent).where(AcademicEvent.user_id == user_id).order_by(AcademicEvent.event_date)).all())
    return [
        {
            "id": str(e.id),
            "title": e.title,
            "event_date": e.event_date.isoformat(),
            "event_type": e.event_type,
            "created_at": e.created_at.isoformat() if e.created_at else None,
        }
        for e in events
    ]


def _export_activity_logs(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    logs = list(db.scalars(select(UserActivityLog).where(UserActivityLog.user_id == user_id).order_by(UserActivityLog.created_at)).all())
    return [
        {
            "id": str(l.id),
            "activity_id": str(l.activity_id),
            "completed_at": l.completed_at.isoformat() if l.completed_at else None,
            "helpfulness_rating": l.helpfulness_rating,
            "is_favorite": l.is_favorite,
            "created_at": l.created_at.isoformat() if l.created_at else None,
        }
        for l in logs
    ]


def _export_cycle_logs(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    logs = list(db.scalars(select(CycleLog).where(CycleLog.user_id == user_id).order_by(CycleLog.period_start)).all())
    return [
        {
            "id": str(c.id),
            "period_start": c.period_start.isoformat(),
            "period_end": c.period_end.isoformat() if c.period_end else None,
            "created_at": c.created_at.isoformat() if c.created_at else None,
        }
        for c in logs
    ]


def _export_study_plans(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    plans = list(db.scalars(select(StudyPlan).where(StudyPlan.user_id == user_id).order_by(StudyPlan.week_start)).all())
    results = []
    for p in plans:
        items = [
            {
                "id": str(item.id),
                "plan_date": item.plan_date.isoformat(),
                "suggested_load": item.suggested_load,
                "adjusted_load": item.adjusted_load,
                "target_study_minutes": item.target_study_minutes,
                "status": item.status,
                "user_notes": item.user_notes,
                "completed": item.completed,
                "exam_event_id": str(item.exam_event_id) if item.exam_event_id else None,
                "activity_id": str(item.activity_id) if item.activity_id else None,
            }
            for item in p.items
        ]
        results.append(
            {
                "id": str(p.id),
                "week_start": p.week_start.isoformat(),
                "days": p.days,
                "mode": p.mode,
                "uses_cycle_data": p.uses_cycle_data,
                "checkin_days_used": p.checkin_days_used,
                "created_at": p.created_at.isoformat() if p.created_at else None,
                "items": items,
            }
        )
    return results


def _export_resource_reports(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    reports = list(db.scalars(select(ResourceReport).where(ResourceReport.reporter_id == user_id).order_by(ResourceReport.created_at)).all())
    return [
        {
            "id": str(r.id),
            "resource_id": str(r.resource_id),
            "reason": r.reason,
            "note": r.note,
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
            "resolved_at": r.resolved_at.isoformat() if r.resolved_at else None,
            "resolved_note": r.resolved_note,
        }
        for r in reports
    ]


def _export_account_events(db: Session, user_id: uuid.UUID) -> List[Dict[str, Any]]:
    events = list(db.scalars(select(AccountEvent).where(AccountEvent.user_id == user_id).order_by(AccountEvent.created_at)).all())
    return [
        {
            "id": str(e.id),
            "event_type": e.event_type.value if hasattr(e.event_type, "value") else str(e.event_type),
            "created_at": e.created_at.isoformat() if e.created_at else None,
        }
        for e in events
    ]


# Register all feature sections and their tables
export_registry.register("preferences", "user_preferences", _export_user_preferences)
export_registry.register("checkins", "mood_checkins", _export_checkins)
export_registry.register("journal", "journal_entries", _export_journal)
export_registry.register("academic_events", "academic_events", _export_academic_events)
export_registry.register("activity_logs", "user_activity_logs", _export_activity_logs)
export_registry.register("cycle_logs", "cycle_logs", _export_cycle_logs)
export_registry.register("study_plans", "study_plans", _export_study_plans)
export_registry.register("resource_reports", "resource_reports", _export_resource_reports)
export_registry.register("account_events", "account_events", _export_account_events)
