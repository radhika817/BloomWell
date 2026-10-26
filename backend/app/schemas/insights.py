from datetime import date
from typing import Dict, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field


class MetricObservation(BaseModel):
    model_config = ConfigDict(extra="forbid")
    week_average: float
    baseline_average: float
    diff: float
    code: Literal["HIGHER_THAN_USUAL", "LOWER_THAN_USUAL", "SIMILAR"]


class WeeklyInsightDaysNeeded(BaseModel):
    model_config = ConfigDict(extra="forbid")
    week: int
    baseline: int


class WeeklyInsightResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["sufficient_data", "not_enough_data"]
    week_start: date
    days_needed: Optional[WeeklyInsightDaysNeeded] = None
    metrics: Optional[Dict[str, MetricObservation]] = None
    sample_sizes: Optional[Dict[str, int]] = None


class ExamContextObservation(BaseModel):
    model_config = ConfigDict(extra="forbid")
    pre_event_average: float
    baseline_average: float
    diff: float
    code: str


class ExamContextInsightResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["sufficient_data", "not_enough_data"]
    qualifying_events_count: Optional[int] = None
    events_needed: Optional[int] = None
    stress: Optional[ExamContextObservation] = None
    energy: Optional[ExamContextObservation] = None
    sample_sizes: Optional[Dict[str, int]] = None
