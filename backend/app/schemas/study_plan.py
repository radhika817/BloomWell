from datetime import date, datetime
from typing import List, Literal, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field


class StudyPlanGenerateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    week_start: date = Field(..., description="Start date of the 7-day study plan (YYYY-MM-DD)")
    replace: bool = Field(default=False, description="Replace existing plan for this week if true")


class StudyPlanItemPatchRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["accepted", "edited", "skipped"]
    suggested_load: Optional[Literal["light", "normal", "focus"]] = None


class StudyPlanItemResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: uuid.UUID
    study_plan_id: uuid.UUID
    plan_date: date
    suggested_load: str
    reason_codes: List[str]
    academic_event_id: Optional[uuid.UUID] = None
    activity_id: Optional[uuid.UUID] = None
    status: str
    updated_at: datetime


class PersonalizationInfo(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["default", "personalized"]
    checkin_days_used: int
    checkin_days_needed: int = 14


class StudyPlanResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    id: uuid.UUID
    week_start: date
    days: int
    mode: str
    uses_cycle_data: bool
    personalization: PersonalizationInfo
    items: List[StudyPlanItemResponse]
    created_at: datetime
