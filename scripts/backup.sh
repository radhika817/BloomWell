#!/usr/bin/env bash
# BloomWell Database Backup Utility
# Creates timestamped custom-format PostgreSQL dumps with rotation and optional encryption.

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/bloomwell}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP=$(date -u +"%Y%m%d_%H%M%SZ")
DUMP_FILE="${BACKUP_DIR}/bloomwell_${TIMESTAMP}.dump"

mkdir -p "${BACKUP_DIR}"
chmod 700 "${BACKUP_DIR}"

echo "[backup] Starting BloomWell database backup at ${TIMESTAMP}..."

# Execute pg_dump using connection string or environment variables without printing secrets
if [ -n "${DATABASE_URL:-}" ]; then
    pg_dump -Fc --no-owner --no-privileges --dbname="${DATABASE_URL}" -f "${DUMP_FILE}"
else
    pg_dump -Fc --no-owner --no-privileges -f "${DUMP_FILE}"
fi

chmod 600 "${DUMP_FILE}"
echo "[backup] Unencrypted dump written to ${DUMP_FILE} (permissions 0600)."

# Optional symmetric encryption if BACKUP_PASSPHRASE is provided
FINAL_FILE="${DUMP_FILE}"
if [ -n "${BACKUP_PASSPHRASE:-}" ]; then
    ENCRYPTED_FILE="${DUMP_FILE}.enc"
    echo "[backup] Encrypting dump with AES-256-CBC using BACKUP_PASSPHRASE..."
    openssl enc -aes-256-cbc -salt -pbkdf2 -in "${DUMP_FILE}" -out "${ENCRYPTED_FILE}" -pass env:BACKUP_PASSPHRASE
    chmod 600 "${ENCRYPTED_FILE}"
    rm -f "${DUMP_FILE}"
    FINAL_FILE="${ENCRYPTED_FILE}"
    echo "[backup] Encrypted dump saved to ${FINAL_FILE}."
fi

# Rotate backups older than BACKUP_RETENTION_DAYS
echo "[backup] Pruning backups older than ${RETENTION_DAYS} days in ${BACKUP_DIR}..."
find "${BACKUP_DIR}" -type f \( -name "bloomwell_*.dump" -o -name "bloomwell_*.dump.enc" \) -mtime "+${RETENTION_DAYS}" -print -delete || true

echo "[backup] Backup completed successfully: ${FINAL_FILE}"
echo "================================================================================"
echo "IMPORTANT NOTICE: Do NOT leave database backups solely on this server!"
echo "Automate copying this dump to an off-site, access-restricted, encrypted location"
echo "(e.g., an AWS S3 bucket with Object Lock and KMS encryption) for true disaster recovery."
echo "================================================================================"
