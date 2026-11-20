"""Owner-scoped repository for menstrual cycle logs."""

import uuid
from datetime import date
from typing import List, Optional
from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.models.cycle import CycleLog


class CycleRepository:
    """Repository managing user-owned cycle logs with strict owner scoping."""

    def __init__(self, db: Session):
        self.db = db

    def create_cycle_log(
        self,
        user_id: uuid.UUID,
        period_start: date,
        period_end: Optional[date] = None,
    ) -> CycleLog:
        """Create a new cycle log for the specified user."""
        log = CycleLog(
            user_id=user_id,
            period_start=period_start,
            period_end=period_end,
        )
        self.db.add(log)
        self.db.commit()
        self.db.refresh(log)
        return log

    def get_all_for_user(self, user_id: uuid.UUID) -> List[CycleLog]:
        """Fetch all cycle logs for a user ordered by period_start ascending."""
        stmt = (
            select(CycleLog)
            .where(CycleLog.user_id == user_id)
            .order_by(CycleLog.period_start.asc())
        )
        return list(self.db.scalars(stmt).all())

    def get_overlapping_periods(
        self,
        user_id: uuid.UUID,
        from_date: date,
        to_date: date,
    ) -> List[CycleLog]:
        """
        Fetch recorded periods overlapping [from_date, to_date].
        A period overlaps if its start or end falls in the range, or it spans it.
        """
        stmt = (
            select(CycleLog)
            .where(
                CycleLog.user_id == user_id,
                or_(
                    and_(
                        CycleLog.period_start <= to_date,
                        CycleLog.period_end.is_not(None),
                        CycleLog.period_end >= from_date,
                    ),
                    and_(
                        CycleLog.period_start >= from_date,
                        CycleLog.period_start <= to_date,
                    ),
                ),
            )
            .order_by(CycleLog.period_start.asc())
        )
        return list(self.db.scalars(stmt).all())
