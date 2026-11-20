"""Pure cycle estimation algorithm based on docs/architecture.md Section 8.1."""

from dataclasses import dataclass
from datetime import date, timedelta
import statistics
from typing import List, Optional


@dataclass(frozen=True)
class CycleEstimateResult:
    """Pure dataclass representing the outcome of cycle estimation."""

    status: str  # 'estimate', 'not_enough_data', 'too_variable'
    typical_cycle_length_days: Optional[int] = None
    cycles_counted: int = 0
    needed_cycles: Optional[int] = None
    estimated_range_start: Optional[date] = None
    estimated_range_end: Optional[date] = None
    explanation: Optional[str] = None


def calculate_cycle_estimate(
    period_starts: List[date],
    max_gap_days: int = 90,
    min_usable_cycles: int = 3,
    max_recent_cycles: int = 6,
    max_spread_threshold: int = 15,
) -> CycleEstimateResult:
    """
    Pure function computing conservative next cycle window estimate.

    Guardrails (docs/architecture.md 8.1):
    1. Consecutive day differences between recorded period starts.
    2. Drop gaps > max_gap_days (default 90) as likely missed logs.
    3. Require >= min_usable_cycles (default 3); otherwise return not_enough_data.
    4. Median of last up to max_recent_cycles (default 6) as typical length.
    5. If spread (max - min) > max_spread_threshold (15 days), return too_variable.
    6. Date range = last_start + typical +/- max(2, round(MAD)).
    7. Never returns an exact single date, never uses diagnostic terms.
    """
    sorted_starts = sorted(set(period_starts))
    if len(sorted_starts) < 2:
        return CycleEstimateResult(
            status="not_enough_data",
            cycles_counted=0,
            needed_cycles=min_usable_cycles,
            explanation="Log a few more cycles to see an estimate.",
        )

    # 1. Compute consecutive lengths
    lengths = [
        (sorted_starts[i + 1] - sorted_starts[i]).days
        for i in range(len(sorted_starts) - 1)
    ]

    # 2. Filter out gaps above 90 days and non-positive lengths
    usable_lengths = [l for l in lengths if 0 < l <= max_gap_days]

    # 3. Require at least min_usable_cycles
    if len(usable_lengths) < min_usable_cycles:
        return CycleEstimateResult(
            status="not_enough_data",
            cycles_counted=len(usable_lengths),
            needed_cycles=min_usable_cycles - len(usable_lengths),
            explanation="Log a few more cycles to see an estimate.",
        )

    # 4. Use median of last up to 6 usable lengths
    recent = usable_lengths[-max_recent_cycles:]
    median_length = statistics.median(recent)
    typical_length = int(round(median_length))

    # 5. Check variability
    spread = max(recent) - min(recent)
    if spread > max_spread_threshold:
        return CycleEstimateResult(
            status="too_variable",
            cycles_counted=len(recent),
            typical_cycle_length_days=typical_length,
            explanation="Your logged cycles vary too much for a useful estimate.",
        )

    # 6. Build range using larger of 2 days or MAD (median absolute deviation)
    deviations = [abs(x - median_length) for x in recent]
    mad = statistics.median(deviations)
    margin = max(2, int(round(mad)))

    last_start = sorted_starts[-1]
    range_start = last_start + timedelta(days=typical_length - margin)
    range_end = last_start + timedelta(days=typical_length + margin)

    return CycleEstimateResult(
        status="estimate",
        typical_cycle_length_days=typical_length,
        cycles_counted=len(recent),
        estimated_range_start=range_start,
        estimated_range_end=range_end,
    )
