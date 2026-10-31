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


class ToggleConsentRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool = Field(..., description="Enable or revoke consent.")


class CycleConsentDetail(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool
    enabled_at: Optional[datetime] = None


class JournalAIConsentDetail(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool
    consented_at: Optional[datetime] = None


class AIRecommendationsConsentDetail(BaseModel):
    model_config = ConfigDict(extra="forbid")
    enabled: bool


class ConsentsOverviewResponse(BaseModel):
    """Unified consent management overview."""
    model_config = ConfigDict(extra="forbid")

    cycle_tracking: CycleConsentDetail
    planner_cycle: CycleConsentDetail
    ai_recommendations: AIRecommendationsConsentDetail
    journal_ai: JournalAIConsentDetail
    ai_available: bool
    reminders_enabled: bool


class AIConsentUpdateResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")

    enabled: bool
    consented_at: Optional[datetime] = None
    ai_available: bool
