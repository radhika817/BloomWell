from fastapi import APIRouter

api_v1_router = APIRouter(prefix="/v1")

# Feature routers (auth, checkins, cycles, planner, community, etc.)
# will be mounted here in future steps per docs/architecture.md Section 5.


@api_v1_router.get(
    "/info",
    tags=["Info"],
    summary="API V1 Information",
    description="Provides baseline information about the V1 API prefix.",
)
def get_v1_info() -> dict:
    return {
        "api_version": "v1",
        "description": "BloomWell API V1 - Foundation active",
    }
