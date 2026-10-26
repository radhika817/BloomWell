from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict, Field


class PlannerCycleConsentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool = Field(..., description="Whether cycle data may inform the study planner.")


class PlannerCycleConsentResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool
    consent_recorded_at: Optional[datetime] = None
    deleted_cycle_plans_count: int = Field(
        default=0,
        description="Count of cycle-derived study plans deleted if consent was revoked.",
    )


class CycleTrackingUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    cycle_tracking_enabled: bool = Field(..., description="Enable or disable cycle tracking.")
    delete_data: bool = Field(
        default=False,
        description="If true, permanently delete all recorded cycle data and cycle-derived study plans.",
    )


class CycleTrackingStatusResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    cycle_tracking_enabled: bool
    consent_recorded_at: Optional[datetime] = None
    deleted_cycle_plans_count: int = Field(
        default=0,
        description="Count of cycle-derived study plans deleted in this transaction.",
    )
    deleted_cycle_records_count: int = Field(
        default=0,
        description="Count of cycle records deleted if delete_data was requested.",
    )
