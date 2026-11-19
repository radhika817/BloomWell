#!/usr/bin/env bash
# BloomWell Rollback Script
# Reverts the running API container to the previous tagged image with warnings.

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

COMPOSE_FILE="docker-compose.prod.yml"

echo "=== [rollback] Starting BloomWell Production Rollback ==="

if ! docker image inspect bloomwell-api:previous >/dev/null 2>&1; then
    echo "Error: No rollback image 'bloomwell-api:previous' exists on this host!" >&2
    exit 1
fi

echo "================================================================================"
echo "WARNING: Rollback will restart the previous container image (bloomwell-api:previous)."
echo "NOTE: Database migrations (Alembic) are NOT reverted automatically."
echo "Per BloomWell architectural rules, migrations must remain backward-compatible"
echo "for one release to allow safe rollbacks without manual down-revisions."
echo "================================================================================"

echo "[rollback] Retagging bloomwell-api:previous to bloomwell-api:latest..."
docker tag bloomwell-api:previous bloomwell-api:latest

echo "[rollback] Restarting api container with rolled-back image..."
docker compose -f "${COMPOSE_FILE}" up -d --no-deps api

# Verify health check
echo "[rollback] Verifying health check on rolled-back container..."
sleep 5
if docker compose -f "${COMPOSE_FILE}" exec -T api curl -s -f http://127.0.0.1:8000/health >/dev/null 2>&1; then
    echo "[rollback] API health check confirmed healthy on rolled-back container!"
else
    echo "[rollback] Warning: Health check did not immediately respond. Check container logs:"
    echo "docker compose -f ${COMPOSE_FILE} logs --tail=50 api"
fi

echo "=== [rollback] Rollback completed successfully! ==="
