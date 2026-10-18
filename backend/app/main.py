import logging
import uuid
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, HTTPException, Request, Response, status
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.middleware.base import BaseHTTPMiddleware

from app.api.health import router as health_router
from app.api.v1.router import api_v1_router
from app.core.config import settings
from app.core.logging import setup_logging

logger = logging.getLogger("bloomwell.api")


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan context manager for startup and shutdown events."""
    setup_logging(settings.LOG_LEVEL)
    logger.info(
        "BloomWell API startup",
        extra={
            "app_env": settings.APP_ENV,
            "ai_provider": settings.AI_PROVIDER,
        },
    )
    yield
    logger.info("BloomWell API shutdown")


class RequestIdMiddleware(BaseHTTPMiddleware):
    """
    Middleware that assigns a unique correlation ID (X-Request-ID) to every incoming request.
    If the caller supplied an X-Request-ID header, it is reused; otherwise a new UUID is generated.
    The ID is attached to request.state and returned in response headers.
    """

    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = request.headers.get("X-Request-ID") or str(uuid.uuid4())
        request.state.request_id = request_id

        # Notice: per AGENTS.md rule 4 and docs/architecture.md, NEVER log request bodies!
        # Only log high-level metadata (method, path, client ip).
        logger.info(
            "Request started",
            extra={
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
            },
        )

        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id

        logger.info(
            "Request finished",
            extra={
                "request_id": request_id,
                "status_code": response.status_code,
            },
        )
        return response


def create_application() -> FastAPI:
    """FastAPI application factory."""
    app = FastAPI(
        title="BloomWell API",
        description="Privacy-first menstrual wellness and peer-support platform backend.",
        version="0.1.0",
        lifespan=lifespan,
    )

    # 1. Request ID Middleware
    app.add_middleware(RequestIdMiddleware)

    # 2. CORS Middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # 3. Exception Handlers ensuring consistent problem-details JSON error format
    @app.exception_handler(StarletteHTTPException)
    async def http_exception_handler(
        request: Request, exc: StarletteHTTPException
    ) -> JSONResponse:
        request_id = getattr(request.state, "request_id", None)
        headers = {"X-Request-ID": request_id} if request_id else {}
        if getattr(exc, "headers", None):
            headers.update(exc.headers)
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": f"HTTP_{exc.status_code}",
                "message": str(exc.detail),
                "details": None,
                "request_id": request_id,
            },
            headers=headers if headers else None,
        )

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(
        request: Request, exc: RequestValidationError
    ) -> JSONResponse:
        request_id = getattr(request.state, "request_id", None)
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "code": "VALIDATION_ERROR",
                "message": "Invalid request parameters or payload",
                "details": jsonable_encoder(exc.errors()),
                "request_id": request_id,
            },
            headers={"X-Request-ID": request_id} if request_id else None,
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        request_id = getattr(request.state, "request_id", None)
        logger.error(
            "Unhandled server exception",
            extra={
                "request_id": request_id,
                "error_type": type(exc).__name__,
            },
            exc_info=True,
        )
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "code": "INTERNAL_SERVER_ERROR",
                "message": "An internal server error occurred.",
                "details": None,
                "request_id": request_id,
            },
            headers={"X-Request-ID": request_id} if request_id else None,
        )

    # 4. Mount Routers
    # GET /health directly on root per Requirement 5
    app.include_router(health_router)
    # Everything else under /v1 prefix
    app.include_router(api_v1_router)

    return app


app = create_application()
