from dataclasses import dataclass, field
from datetime import date, timedelta
import math
from typing import Dict, List, Optional, Set
import uuid


ALLOWED_REASON_CODES = {
    "NOT_ENOUGH_HISTORY",
    "DEFAULT_PLAN",
    "WEEKDAY_ENERGY_HIGHER",
    "WEEKDAY_ENERGY_LOWER",
    "CYCLE_RECORDED_PERIOD_LOW_ENERGY",
    "EVENT_PREP",
    "EVENT_DAY",
    "KEEP_OPTION_PRESERVED",
}


@dataclass(frozen=True)
class AcademicEventInput:
    id: uuid.UUID
    event_date: date
    title: str
    event_type: str = "exam"


@dataclass(frozen=True)
class CycleRecordInput:
    period_start: date
    period_end: Optional[date] = None


@dataclass(frozen=True)
class ActivityCandidate:
    id: uuid.UUID
    is_favorite: bool = False
    is_published: bool = True
    category: str = "study_break"


@dataclass
class PlannedDayItem:
    plan_date: date
    suggested_load: str  # "light", "normal", "focus"
    reason_codes: List[str] = field(default_factory=list)
    academic_event_id: Optional[uuid.UUID] = None
    activity_id: Optional[uuid.UUID] = None


@dataclass
class GeneratedPlanOutput:
    week_start: date
    days: int
    mode: str  # "default" | "personalized"
    uses_cycle_data: bool
    checkin_days_used: int
    items: List[PlannedDayItem]


def compute_standard_deviation(values: List[float]) -> float:
    """Compute sample standard deviation for a list of values."""
    if len(values) < 2:
        return 0.0
    mean = sum(values) / len(values)
    variance = sum((x - mean) ** 2 for x in values) / (len(values) - 1)
    return math.sqrt(variance)


def generate_study_plan_schedule(
    week_start: date,
    daily_energy_history: Dict[date, float],
    academic_events: List[AcademicEventInput],
    cycle_consent: bool,
    cycle_tracking_enabled: bool,
    recorded_cycles: List[CycleRecordInput],
    break_activities: List[ActivityCandidate],
) -> GeneratedPlanOutput:
    """
    Pure deterministic function generating a 7-day study plan schedule.
    No I/O, no network calls, no AI.
    """
    plan_dates = [week_start + timedelta(days=i) for i in range(7)]
    distinct_checkin_days = len(daily_energy_history)

    # Mode determination: >= 14 distinct days in the last 28 days -> personalized
    is_personalized = distinct_checkin_days >= 14
    mode = "personalized" if is_personalized else "default"

    # Map events by date
    events_by_date: Dict[date, AcademicEventInput] = {}
    for ev in academic_events:
        events_by_date[ev.event_date] = ev

    # 1. Base load determination
    initial_loads: Dict[date, str] = {}
    initial_reasons: Dict[date, List[str]] = {}
    weekday_means: Dict[int, float] = {}

    if not is_personalized:
        # Default mode: all days normal
        for d in plan_dates:
            initial_loads[d] = "normal"
            initial_reasons[d] = ["NOT_ENOUGH_HISTORY"]

        # Default mode exam prep rules:
        # 2nd to 5th day before an event: focus (EVENT_PREP)
        # Event day itself: normal (EVENT_DAY)
        for ev in academic_events:
            for prep_offset in range(2, 6):
                prep_date = ev.event_date - timedelta(days=prep_offset)
                if prep_date in initial_loads:
                    initial_loads[prep_date] = "focus"
                    initial_reasons[prep_date] = ["EVENT_PREP"]
            if ev.event_date in initial_loads:
                initial_loads[ev.event_date] = "normal"
                initial_reasons[ev.event_date] = ["EVENT_DAY"]
    else:
        # Personalized mode: compute mean and standard deviation
        energy_values = list(daily_energy_history.values())
        mean_energy = sum(energy_values) / len(energy_values)
        sd_energy = compute_standard_deviation(energy_values)

        if sd_energy < 0.5:
            # Differences are too small to mean anything -> all normal
            for d in plan_dates:
                initial_loads[d] = "normal"
                initial_reasons[d] = ["DEFAULT_PLAN"]
        else:
            # Group daily energy by weekday (0 = Monday, ..., 6 = Sunday)
            weekday_samples: Dict[int, List[float]] = {i: [] for i in range(7)}
            for d, score in daily_energy_history.items():
                weekday_samples[d.weekday()].append(score)

            for i in range(7):
                if len(weekday_samples[i]) >= 2:
                    weekday_means[i] = sum(weekday_samples[i]) / len(weekday_samples[i])

            for d in plan_dates:
                w = d.weekday()
                if w in weekday_means:
                    w_mean = weekday_means[w]
                    if w_mean < mean_energy - (0.5 * sd_energy):
                        initial_loads[d] = "light"
                        initial_reasons[d] = ["WEEKDAY_ENERGY_LOWER"]
                    elif w_mean > mean_energy + (0.5 * sd_energy):
                        initial_loads[d] = "focus"
                        initial_reasons[d] = ["WEEKDAY_ENERGY_HIGHER"]
                    else:
                        initial_loads[d] = "normal"
                        initial_reasons[d] = ["DEFAULT_PLAN"]
                else:
                    initial_loads[d] = "normal"
                    initial_reasons[d] = ["DEFAULT_PLAN"]

    # 2. Cycle adjustment
    # Evaluated only if cycle tracking is enabled AND planner cycle consent is granted
    uses_cycle_data = False
    if cycle_consent and cycle_tracking_enabled:
        uses_cycle_data = True  # adjustment evaluated/applied

        # Use last up to 6 recorded cycles
        recent_cycles = recorded_cycles[-6:]
        all_recorded_period_dates: Set[date] = set()

        for c in recent_cycles:
            p_start = c.period_start
            p_end = c.period_end if c.period_end else (p_start + timedelta(days=4))
            curr = p_start
            while curr <= p_end:
                all_recorded_period_dates.add(curr)
                curr += timedelta(days=1)

        # Requirement: at least 3 recorded periods and at least 6 period-day check-ins
        period_checkin_scores = [
            score for d, score in daily_energy_history.items()
            if d in all_recorded_period_dates
        ]
        non_period_checkin_scores = [
            score for d, score in daily_energy_history.items()
            if d not in all_recorded_period_dates
        ]

        if len(recent_cycles) >= 3 and len(period_checkin_scores) >= 6 and non_period_checkin_scores:
            avg_period_energy = sum(period_checkin_scores) / len(period_checkin_scores)
            avg_other_energy = sum(non_period_checkin_scores) / len(non_period_checkin_scores)

            if avg_other_energy - avg_period_energy >= 0.7:
                # Apply adjustment: days in plan window that fall inside a RECORDED period move one step toward light
                for d in plan_dates:
                    if d in all_recorded_period_dates:
                        current_load = initial_loads[d]
                        if current_load == "focus":
                            initial_loads[d] = "normal"
                            initial_reasons[d].append("CYCLE_RECORDED_PERIOD_LOW_ENERGY")
                        elif current_load == "normal":
                            initial_loads[d] = "light"
                            initial_reasons[d].append("CYCLE_RECORDED_PERIOD_LOW_ENERGY")

    # 3. Exam rules (applied last)
    for ev in academic_events:
        # 7 days before event: [event_date - 7, event_date - 1]
        pre_event_window = [ev.event_date - timedelta(days=k) for k in range(7, 0, -1)]

        # Find 3-day stretches within the pre-event window that fall in our plan
        for idx in range(len(pre_event_window) - 2):
            stretch = pre_event_window[idx : idx + 3]
            if all(d in initial_loads for d in stretch):
                if all(initial_loads[d] == "light" for d in stretch):
                    # Raise the highest-energy day in that stretch to normal
                    # If tied or unknown, use weekday mean or first day
                    best_day = max(
                        stretch,
                        key=lambda d: weekday_means.get(d.weekday(), 0.0),
                    )
                    initial_loads[best_day] = "normal"
                    if "KEEP_OPTION_PRESERVED" not in initial_reasons[best_day]:
                        initial_reasons[best_day].append("KEEP_OPTION_PRESERVED")

        # The event day is never light
        if ev.event_date in initial_loads:
            if initial_loads[ev.event_date] == "light":
                initial_loads[ev.event_date] = "normal"
            if "EVENT_DAY" not in initial_reasons[ev.event_date]:
                initial_reasons[ev.event_date].append("EVENT_DAY")

    # 4. Break activity assignment
    # Filter published study break activities
    available_breaks = [
        a for a in break_activities
        if a.is_published and a.category == "study_break"
    ]
    # Sort deterministically: favorites first, then by UUID string
    available_breaks.sort(key=lambda a: (not a.is_favorite, str(a.id)))

    assigned_activities: Dict[date, Optional[uuid.UUID]] = {}
    last_assigned_id: Optional[uuid.UUID] = None

    if available_breaks:
        for d in plan_dates:
            # Pick next activity that is not the same as yesterday's
            chosen = None
            for candidate in available_breaks:
                if candidate.id != last_assigned_id or len(available_breaks) == 1:
                    chosen = candidate
                    break
            if chosen:
                assigned_activities[d] = chosen.id
                last_assigned_id = chosen.id
            else:
                assigned_activities[d] = None
    else:
        for d in plan_dates:
            assigned_activities[d] = None

    # 5. Build final PlannedDayItem list
    items: List[PlannedDayItem] = []
    for d in plan_dates:
        # Associated academic event if on this day or nearby
        event_on_day = events_by_date.get(d)
        event_id = event_on_day.id if event_on_day else None

        # Clean reasons to only allowed reason codes
        valid_reasons = [r for r in initial_reasons[d] if r in ALLOWED_REASON_CODES]
        if not valid_reasons:
            valid_reasons = ["DEFAULT_PLAN"]

        items.append(
            PlannedDayItem(
                plan_date=d,
                suggested_load=initial_loads[d],
                reason_codes=valid_reasons,
                academic_event_id=event_id,
                activity_id=assigned_activities[d],
            )
        )

    return GeneratedPlanOutput(
        week_start=week_start,
        days=7,
        mode=mode,
        uses_cycle_data=uses_cycle_data,
        checkin_days_used=distinct_checkin_days,
        items=items,
    )
