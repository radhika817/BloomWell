"""Owner-scoped repository for daily symptom logs."""

import uuid
from datetime import date
from typing import List, Optional
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.cycle import SymptomLog


class SymptomRepository:
    """Repository managing user-owned symptom logs with strict owner scoping."""

    def __init__(self, db: Session):
        self.db = db

    def create_symptom_log(
        self,
        user_id: uuid.UUID,
        date: date,
        symptom_type: str,
        severity: int,
        custom_label: Optional[str] = None,
        notes: Optional[str] = None,
        client_id: Optional[uuid.UUID] = None,
    ) -> SymptomLog:
        """Create a new symptom log for the specified user."""
        log = SymptomLog(
            user_id=user_id,
            date=date,
            symptom_type=symptom_type,
            severity=severity,
            custom_label=custom_label,
            notes=notes,
            client_id=client_id,
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log

    def count_symptoms_in_range(
        self,
        user_id: uuid.UUID,
        from_date: date,
        to_date: date,
    ) -> int:
        """Count the total number of symptom rows for a user in the date range."""
        stmt = (
            select(func.count())
            .select_from(SymptomLog)
            .where(
                SymptomLog.user_id == user_id,
                SymptomLog.date >= from_date,
                SymptomLog.date <= to_date,
            )
        )
        return self.db.scalar(stmt) or 0

    def get_symptoms_in_range(
        self,
        user_id: uuid.UUID,
        from_date: date,
        to_date: date,
    ) -> List[SymptomLog]:
        """Fetch all symptom logs for a user in [from_date, to_date] ordered by date ascending."""
        stmt = (
            select(SymptomLog)
            .where(
                SymptomLog.user_id == user_id,
                SymptomLog.date >= from_date,
                SymptomLog.date <= to_date,
            )
            .order_by(SymptomLog.date.asc(), SymptomLog.created_at.asc())
        )
        return list(self.db.scalars(stmt).all())
