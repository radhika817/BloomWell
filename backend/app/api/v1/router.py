from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.checkins import router as checkins_router
from app.api.v1.insights import router as insights_router
from app.api.v1.journal import router as journal_router
from app.api.v1.me import router as me_router
from app.api.v1.study_plans import router as study_plans_router
from app.api.v1.resources import router as resources_router

api_v1_router = APIRouter(prefix="/v1")

# Mount routers
api_v1_router.include_router(auth_router)
api_v1_router.include_router(me_router)
api_v1_router.include_router(checkins_router)
api_v1_router.include_router(journal_router)
api_v1_router.include_router(insights_router)
api_v1_router.include_router(study_plans_router)
api_v1_router.include_router(resources_router)


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
