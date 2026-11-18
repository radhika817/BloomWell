# Pinned official slim base image for reproducible, minimal production builds
FROM python:3.12.7-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install minimal runtime dependencies (curl for container health checks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install production dependencies only (no dev/test requirements)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create an unprivileged non-root user and group
RUN groupadd -g 10001 appuser && \
    useradd -u 10001 -g appuser -s /bin/sh -d /app -M appuser

# Copy application source and migrations (tests and .env excluded via .dockerignore)
COPY alembic.ini .
COPY migrations ./migrations
COPY app ./app

# Set ownership to unprivileged user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8000

# Periodic health check against /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://127.0.0.1:8000/health || exit 1

# Graceful termination signal
STOPSIGNAL SIGTERM

# Run a single uvicorn worker by default.
# NOTE: The sliding-window rate limiter in BloomWell is in-memory and per-process;
# running multiple workers multiplies the effective request limits.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--timeout-graceful-shutdown", "15"]
