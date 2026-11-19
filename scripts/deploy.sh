#!/usr/bin/env bash
# BloomWell Safe Zero-Downtime Deployment Script
# Idempotent release execution with pre-migration verification, health checks, and rollback staging.

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

COMPOSE_FILE="docker-compose.prod.yml"

echo "=== [deploy] Starting BloomWell Production Deployment ==="

# 1. Pull latest code
echo "[deploy] Pulling latest code from origin..."
git pull --ff-only origin main || {
    echo "Error: Failed to pull latest code. Working tree may be dirty or divergent." >&2
    exit 1
}

# 2. Tag currently running image for rollback if it exists
if docker image inspect bloomwell-api:latest >/dev/null 2>&1; then
    echo "[deploy] Tagging current bloomwell-api:latest as bloomwell-api:previous for rollback..."
    docker tag bloomwell-api:latest bloomwell-api:previous
fi

# 3. Build new api image
echo "[deploy] Building new API container image..."
docker compose -f "${COMPOSE_FILE}" build api

# 4. Run database migrations as an isolated one-off step BEFORE container switch
echo "[deploy] Running database migrations (alembic upgrade head)..."
if ! docker compose -f "${COMPOSE_FILE}" run --rm --no-deps api alembic upgrade head; then
    echo "================================================================================" >&2
    echo "CRITICAL FAILURE: Database migration failed! Aborting deployment." >&2
    echo "Existing container was NOT modified." >&2
    echo "================================================================================" >&2
    exit 1
fi

# 5. Switch to new container
echo "[deploy] Starting updated api container..."
docker compose -f "${COMPOSE_FILE}" up -d --no-deps api

# Ensure caddy is running and aware of internal routing
docker compose -f "${COMPOSE_FILE}" up -d --no-deps caddy

# 6. Wait for /health to report healthy
echo "[deploy] Waiting for API health check to report healthy (timeout 60s)..."
MAX_RETRIES=12
RETRY_COUNT=0
HEALTHY=false

while [ "${RETRY_COUNT}" -lt "${MAX_RETRIES}" ]; do
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Check container health status via internal health endpoint
    if docker compose -f "${COMPOSE_FILE}" exec -T api curl -s -f http://127.0.0.1:8000/health >/dev/null 2>&1; then
        echo "[deploy] API health check succeeded on attempt ${RETRY_COUNT}!"
        HEALTHY=true
        break
    else
        echo "[deploy] Health check pending (attempt ${RETRY_COUNT}/${MAX_RETRIES})..."
    fi
done

if [ "${HEALTHY}" != true ]; then
    echo "================================================================================" >&2
    echo "CRITICAL FAILURE: API container failed health check after deployment!" >&2
    echo "Run ./scripts/rollback.sh immediately to restore the previous image." >&2
    echo "================================================================================" >&2
    exit 1
fi

echo "=== [deploy] Deployment completed successfully! ==="
