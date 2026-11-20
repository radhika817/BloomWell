"""Doctor-visit summary data collection service."""

from collections import defaultdict
from dataclasses import dataclass
from datetime import date
from typing import Dict, List, Optional, Set
import uuid
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.repositories.cycle_repository import CycleRepository
from app.repositories.symptom_repository import SymptomRepository
from app.schemas.doctor_summary import DoctorSummaryRequest
from app.services.cycle_algorithm import calculate_cycle_estimate


class SummaryTooLargeError(HTTPException):
    """Exception raised when the symptom count exceeds DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS."""

    def __init__(
        self,
        message: str = "Requested summary range contains too many symptom rows. Please narrow the date range.",
    ):
        super().__init__(
            status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            detail={"code": "summary_too_large", "message": message},
        )
        self.code = "summary_too_large"
        self.message = message

    def __str__(self) -> str:
        return self.message


@dataclass(frozen=True)
class PeriodSummaryItem:
    """Plain dataclass for a recorded period item."""

    period_start: date
    period_end: Optional[date]
    cycle_length_days: Optional[int]


@dataclass(frozen=True)
class SymptomSummaryGroup:
    """Plain dataclass for grouped symptoms of a specific type / custom label."""

    symptom_type: str
    custom_label: Optional[str]
    days_logged: int
    min_severity: int
    max_severity: int
    dates: List[date]
    notes: List[str]


@dataclass(frozen=True)
class EstimateSummaryItem:
    """Plain dataclass for next cycle window estimate."""

    status: str
    typical_cycle_length_days: int
    estimated_range_start: date
    estimated_range_end: date
    explanation: Optional[str] = None


@dataclass(frozen=True)
class DoctorSummaryData:
    """Collected summary data for PDF generation."""

    user_id: uuid.UUID
    from_date: date
    to_date: date
    periods: List[PeriodSummaryItem]
    symptoms: List[SymptomSummaryGroup]
    estimate: Optional[EstimateSummaryItem]
    included_categories: List[str]


class DoctorSummaryCollectorService:
    """
    Owner-scoped data collector for Doctor-visit Summary.
    Gathers user's own data using owner-scoped repositories and returns plain dataclasses.
    """

    def __init__(self, db: Session):
        self.db = db
        self.cycle_repo = CycleRepository(db)
        self.symptom_repo = SymptomRepository(db)

    def collect_summary_data(
        self,
        user_id: uuid.UUID,
        req: DoctorSummaryRequest,
    ) -> DoctorSummaryData:
        """Collect all requested summary data for the authenticated user."""
        included_categories: List[str] = []

        # 1. Collect Periods
        periods: List[PeriodSummaryItem] = []
        all_user_cycles = self.cycle_repo.get_all_for_user(user_id)

        if req.include.periods:
            included_categories.append("Recorded periods")
            # Map cycle lengths between consecutive recorded starts
            cycle_length_map: Dict[uuid.UUID, Optional[int]] = {}
            for i, c in enumerate(all_user_cycles):
                if i > 0:
                    cycle_length_map[c.id] = (
                        c.period_start - all_user_cycles[i - 1].period_start
                    ).days
                else:
                    cycle_length_map[c.id] = None

            overlapping_cycles = self.cycle_repo.get_overlapping_periods(
                user_id=user_id,
                from_date=req.from_date,
                to_date=req.to_date,
            )
            for c in overlapping_cycles:
                periods.append(
                    PeriodSummaryItem(
                        period_start=c.period_start,
                        period_end=c.period_end,
                        cycle_length_days=cycle_length_map.get(c.id),
                    )
                )

        # 2. Collect Symptoms
        symptoms: List[SymptomSummaryGroup] = []
        if req.include.symptoms:
            included_categories.append("Logged symptoms")
            if req.include.symptom_notes:
                included_categories.append("Symptom notes")

            count = self.symptom_repo.count_symptoms_in_range(
                user_id=user_id,
                from_date=req.from_date,
                to_date=req.to_date,
            )
            if count > settings.DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS:
                raise SummaryTooLargeError(
                    f"Requested date range contains {count} symptom rows, which exceeds the maximum limit of "
                    f"{settings.DOCTOR_SUMMARY_MAX_SYMPTOM_ROWS}. Please choose a narrower date range."
                )

            symptom_logs = self.symptom_repo.get_symptoms_in_range(
                user_id=user_id,
                from_date=req.from_date,
                to_date=req.to_date,
            )

            # Group by (symptom_type, custom_label)
            grouped: Dict[
                tuple,
                Dict[str, any],
            ] = defaultdict(
                lambda: {
                    "dates": set(),
                    "severities": [],
                    "notes": [],
                }
            )

            for log in symptom_logs:
                key = (log.symptom_type, log.custom_label)
                grouped[key]["dates"].add(log.date)
                grouped[key]["severities"].append(log.severity)
                if req.include.symptom_notes and log.notes and log.notes.strip():
                    grouped[key]["notes"].append(log.notes.strip())

            # Convert grouped dictionary into sorted SymptomSummaryGroup list
            sorted_keys = sorted(
                grouped.keys(),
                key=lambda k: (k[0].lower(), (k[1] or "").lower()),
            )

            for key in sorted_keys:
                stype, clabel = key
                entry = grouped[key]
                sorted_dates = sorted(entry["dates"])
                severities = entry["severities"]
                symptoms.append(
                    SymptomSummaryGroup(
                        symptom_type=stype,
                        custom_label=clabel,
                        days_logged=len(sorted_dates),
                        min_severity=min(severities) if severities else 0,
                        max_severity=max(severities) if severities else 0,
                        dates=sorted_dates,
                        notes=entry["notes"],
                    )
                )

        # 3. Calculate Estimate
        estimate: Optional[EstimateSummaryItem] = None
        if req.include.estimate:
            all_starts = [c.period_start for c in all_user_cycles]
            est_result = calculate_cycle_estimate(all_starts)
            if (
                est_result.status == "estimate"
                and est_result.typical_cycle_length_days is not None
                and est_result.estimated_range_start is not None
                and est_result.estimated_range_end is not None
            ):
                estimate = EstimateSummaryItem(
                    status=est_result.status,
                    typical_cycle_length_days=est_result.typical_cycle_length_days,
                    estimated_range_start=est_result.estimated_range_start,
                    estimated_range_end=est_result.estimated_range_end,
                    explanation=est_result.explanation,
                )
                included_categories.append("Cycle estimate")

        if req.include.questions:
            included_categories.append("Suggested questions")

        return DoctorSummaryData(
            user_id=user_id,
            from_date=req.from_date,
            to_date=req.to_date,
            periods=periods,
            symptoms=symptoms,
            estimate=estimate,
            included_categories=included_categories,
        )
