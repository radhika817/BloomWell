from collections import defaultdict
from datetime import date, timedelta
from typing import Dict, List, Optional
import uuid
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.academic_event import AcademicEvent
from app.models.checkin import MoodCheckin
from app.schemas.insights import (
    ExamContextInsightResponse,
    ExamContextObservation,
    MetricObservation,
    WeeklyInsightDaysNeeded,
    WeeklyInsightResponse,
)


def calculate_weekly_insights(
    week_checkins: List[MoodCheckin],
    baseline_checkins: List[MoodCheckin],
    week_start: date,
) -> WeeklyInsightResponse:
    """
    Pure calculation function comparing week's average (average of daily averages)
    with the user's previous 4 weeks.
    Requires at least 4 distinct days in the week and 7 distinct days in the baseline.
    Observation codes: HIGHER_THAN_USUAL, LOWER_THAN_USUAL, SIMILAR (threshold +/- 0.5).
    """
    # Group by date for target week
    week_by_date: Dict[date, List[MoodCheckin]] = defaultdict(list)
    for c in week_checkins:
        week_by_date[c.local_date].append(c)

    # Group by date for baseline 4 weeks
    baseline_by_date: Dict[date, List[MoodCheckin]] = defaultdict(list)
    for c in baseline_checkins:
        baseline_by_date[c.local_date].append(c)

    week_distinct = len(week_by_date)
    baseline_distinct = len(baseline_by_date)

    if week_distinct < 4 or baseline_distinct < 7:
        return WeeklyInsightResponse(
            status="not_enough_data",
            week_start=week_start,
            days_needed=WeeklyInsightDaysNeeded(
                week=max(0, 4 - week_distinct),
                baseline=max(0, 7 - baseline_distinct),
            ),
        )

    # Compute daily averages for each metric
    metrics_to_eval = [
        ("mood", lambda c: c.mood_score),
        ("stress", lambda c: c.stress_score),
        ("energy", lambda c: c.energy_score),
        ("sleep", lambda c: c.sleep_quality_score),
    ]

    metric_results: Dict[str, MetricObservation] = {}

    for metric_name, getter in metrics_to_eval:
        # Week daily averages
        week_daily_avgs = []
        for d, checkins in week_by_date.items():
            vals = [getter(c) for c in checkins if getter(c) is not None]
            if vals:
                week_daily_avgs.append(sum(vals) / len(vals))

        # Baseline daily averages
        baseline_daily_avgs = []
        for d, checkins in baseline_by_date.items():
            vals = [getter(c) for c in checkins if getter(c) is not None]
            if vals:
                baseline_daily_avgs.append(sum(vals) / len(vals))

        if not week_daily_avgs or not baseline_daily_avgs:
            continue

        week_avg = round(sum(week_daily_avgs) / len(week_daily_avgs), 2)
        base_avg = round(sum(baseline_daily_avgs) / len(baseline_daily_avgs), 2)
        diff = round(week_avg - base_avg, 2)

        # Thresholds: strictly greater than 0.5 is HIGHER, strictly less than -0.5 is LOWER, else SIMILAR
        if diff > 0.5:
            code = "HIGHER_THAN_USUAL"
        elif diff < -0.5:
            code = "LOWER_THAN_USUAL"
        else:
            code = "SIMILAR"

        metric_results[metric_name] = MetricObservation(
            week_average=week_avg,
            baseline_average=base_avg,
            diff=diff,
            code=code,
        )

    return WeeklyInsightResponse(
        status="sufficient_data",
        week_start=week_start,
        metrics=metric_results,
        sample_sizes={
            "week_distinct_days": week_distinct,
            "baseline_distinct_days": baseline_distinct,
        },
    )


def calculate_exam_context_insights(
    events: List[AcademicEvent],
    checkins: List[MoodCheckin],
    reference_date: date,
) -> ExamContextInsightResponse:
    """
    Pure calculation function comparing average stress and energy in the 7 days before
    each academic event in the last 60 days with the user's average outside those windows.
    Requires at least 2 events each with at least 3 check-in days in its window.
    """
    sixty_days_ago = reference_date - timedelta(days=60)
    recent_events = [
        e for e in events
        if sixty_days_ago <= e.event_date <= reference_date
    ]

    checkin_by_date: Dict[date, List[MoodCheckin]] = defaultdict(list)
    for c in checkins:
        checkin_by_date[c.local_date].append(c)

    qualifying_events = []
    pre_event_dates_set = set()

    for event in recent_events:
        window_start = event.event_date - timedelta(days=7)
        window_end = event.event_date - timedelta(days=1)
        window_dates = {
            d for d in checkin_by_date.keys()
            if window_start <= d <= window_end
        }
        if len(window_dates) >= 3:
            qualifying_events.append(event)
            pre_event_dates_set.update(window_dates)

    if len(qualifying_events) < 2:
        return ExamContextInsightResponse(
            status="not_enough_data",
            qualifying_events_count=len(qualifying_events),
            events_needed=max(0, 2 - len(qualifying_events)),
        )

    # Baseline: 8 weeks (56 days) before reference_date, excluding all pre-event windows and event dates
    eight_weeks_ago = reference_date - timedelta(days=56)
    all_event_restricted_dates = set(pre_event_dates_set)
    for e in recent_events:
        all_event_restricted_dates.add(e.event_date)

    baseline_dates_set = {
        d for d in checkin_by_date.keys()
        if eight_weeks_ago <= d <= reference_date and d not in all_event_restricted_dates
    }

    if not pre_event_dates_set or not baseline_dates_set:
        return ExamContextInsightResponse(
            status="not_enough_data",
            qualifying_events_count=len(qualifying_events),
            events_needed=0,
        )

    # Compute daily averages for stress and energy in pre-event windows
    pre_event_stress_days = []
    pre_event_energy_days = []
    for d in pre_event_dates_set:
        cs = checkin_by_date[d]
        pre_event_stress_days.append(sum(c.stress_score for c in cs) / len(cs))
        pre_event_energy_days.append(sum(c.energy_score for c in cs) / len(cs))

    # Compute daily averages for stress and energy in baseline
    baseline_stress_days = []
    baseline_energy_days = []
    for d in baseline_dates_set:
        cs = checkin_by_date[d]
        baseline_stress_days.append(sum(c.stress_score for c in cs) / len(cs))
        baseline_energy_days.append(sum(c.energy_score for c in cs) / len(cs))

    pre_stress_avg = round(sum(pre_event_stress_days) / len(pre_event_stress_days), 2)
    base_stress_avg = round(sum(baseline_stress_days) / len(baseline_stress_days), 2)
    stress_diff = round(pre_stress_avg - base_stress_avg, 2)

    pre_energy_avg = round(sum(pre_event_energy_days) / len(pre_event_energy_days), 2)
    base_energy_avg = round(sum(baseline_energy_days) / len(baseline_energy_days), 2)
    energy_diff = round(pre_energy_avg - base_energy_avg, 2)

    if stress_diff > 0.5:
        stress_code = "STRESS_HIGHER_BEFORE_EVENTS"
    elif stress_diff < -0.5:
        stress_code = "STRESS_LOWER_BEFORE_EVENTS"
    else:
        stress_code = "STRESS_SIMILAR_BEFORE_EVENTS"

    if energy_diff > 0.5:
        energy_code = "ENERGY_HIGHER_BEFORE_EVENTS"
    elif energy_diff < -0.5:
        energy_code = "ENERGY_LOWER_BEFORE_EVENTS"
    else:
        energy_code = "ENERGY_SIMILAR_BEFORE_EVENTS"

    return ExamContextInsightResponse(
        status="sufficient_data",
        qualifying_events_count=len(qualifying_events),
        stress=ExamContextObservation(
            pre_event_average=pre_stress_avg,
            baseline_average=base_stress_avg,
            diff=stress_diff,
            code=stress_code,
        ),
        energy=ExamContextObservation(
            pre_event_average=pre_energy_avg,
            baseline_average=base_energy_avg,
            diff=energy_diff,
            code=energy_code,
        ),
        sample_sizes={
            "pre_event_distinct_days": len(pre_event_dates_set),
            "baseline_distinct_days": len(baseline_dates_set),
            "qualifying_events": len(qualifying_events),
        },
    )


class InsightsService:
    """Service for owner-scoped personal wellness insights."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def get_weekly_insights(
        self,
        user_id: uuid.UUID,
        week_start: date,
    ) -> WeeklyInsightResponse:
        """Fetch check-ins for the target week and prior 4 weeks and compute observations."""
        week_end = week_start + timedelta(days=6)
        baseline_start = week_start - timedelta(days=28)
        baseline_end = week_start - timedelta(days=1)

        # Query owner-scoped check-ins
        stmt = (
            select(MoodCheckin)
            .where(
                MoodCheckin.user_id == user_id,
                MoodCheckin.local_date >= baseline_start,
                MoodCheckin.local_date <= week_end,
            )
            .order_by(MoodCheckin.local_date.asc())
        )
        all_checkins = list(self.db.scalars(stmt).all())

        week_checkins = [c for c in all_checkins if week_start <= c.local_date <= week_end]
        baseline_checkins = [c for c in all_checkins if baseline_start <= c.local_date <= baseline_end]

        return calculate_weekly_insights(week_checkins, baseline_checkins, week_start)

    def get_exam_context_insights(
        self,
        user_id: uuid.UUID,
        reference_date: Optional[date] = None,
    ) -> ExamContextInsightResponse:
        """Fetch academic events and check-ins for the last 60 days and compute observations."""
        ref_date = reference_date or date.today()
        start_date = ref_date - timedelta(days=60)

        # Owner-scoped queries
        event_stmt = (
            select(AcademicEvent)
            .where(
                AcademicEvent.user_id == user_id,
                AcademicEvent.event_date >= start_date,
                AcademicEvent.event_date <= ref_date,
            )
            .order_by(AcademicEvent.event_date.asc())
        )
        events = list(self.db.scalars(event_stmt).all())

        checkin_stmt = (
            select(MoodCheckin)
            .where(
                MoodCheckin.user_id == user_id,
                MoodCheckin.local_date >= start_date - timedelta(days=7),
                MoodCheckin.local_date <= ref_date,
            )
            .order_by(MoodCheckin.local_date.asc())
        )
        checkins = list(self.db.scalars(checkin_stmt).all())

        return calculate_exam_context_insights(events, checkins, ref_date)
