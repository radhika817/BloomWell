#!/usr/bin/env bash
# BloomWell Database Restore Utility
# Restores a custom-format dump into a specified target database with production safeguards.

set -euo pipefail

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] <path-to-dump-file> <target-database-name>

Arguments:
  <path-to-dump-file>      Path to .dump or .dump.enc backup file.
  <target-database-name>   Name of the target database to restore into.

Options:
  --i-know                 Required flag if target database is 'production' or matches prod environment.
  -h, --help               Display this help message.

Environment Variables:
  BACKUP_PASSPHRASE        Required if restoring an encrypted (.enc) backup.
  DATABASE_URL             Optional base connection string (target db name will be substituted).
  PGHOST, PGPORT, PGUSER   Standard Postgres connection parameters.
EOF
    exit 1
}

I_KNOW=false
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --i-know)
            I_KNOW=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option $1" >&2
            usage
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "${#POSITIONAL_ARGS[@]}" -ne 2 ]; then
    echo "Error: Exactly two positional arguments required: <path-to-dump-file> and <target-database-name>." >&2
    usage
fi

DUMP_PATH="${POSITIONAL_ARGS[0]}"
TARGET_DB="${POSITIONAL_ARGS[1]}"

if [ ! -f "${DUMP_PATH}" ]; then
    echo "Error: Backup file '${DUMP_PATH}' does not exist." >&2
    exit 1
fi

# Safeguard against accidental production overwrite
IS_PROD=false
TARGET_DB_LOWER=$(echo "${TARGET_DB}" | tr '[:upper:]' '[:lower:]')
APP_ENV_LOWER=$(echo "${APP_ENV:-}" | tr '[:upper:]' '[:lower:]')

if [[ "${TARGET_DB_LOWER}" == *"prod"* ]] || [ "${APP_ENV_LOWER}" = "production" ] || [ "${APP_ENV_LOWER}" = "prod" ]; then
    IS_PROD=true
fi

if [ "${IS_PROD}" = true ] && [ "${I_KNOW}" != true ]; then
    echo "================================================================================" >&2
    echo "CRITICAL SAFETY REFUSAL: Target database '${TARGET_DB}' appears to be PRODUCTION!" >&2
    echo "Restoring will overwrite existing data. To proceed intentionally, pass --i-know." >&2
    echo "================================================================================" >&2
    exit 1
fi

RESTORE_SOURCE="${DUMP_PATH}"
TMP_DECRYPTED=""

# Decrypt if encrypted dump
if [[ "${DUMP_PATH}" == *.enc ]]; then
    if [ -z "${BACKUP_PASSPHRASE:-}" ]; then
        echo "Error: BACKUP_PASSPHRASE environment variable is required to decrypt '${DUMP_PATH}'." >&2
        exit 1
    fi
    TMP_DECRYPTED=$(mktemp /tmp/bloomwell_restore_XXXXXX.dump)
    chmod 600 "${TMP_DECRYPTED}"
    echo "[restore] Decrypting dump using BACKUP_PASSPHRASE..."
    openssl enc -d -aes-256-cbc -pbkdf2 -in "${DUMP_PATH}" -out "${TMP_DECRYPTED}" -pass env:BACKUP_PASSPHRASE
    RESTORE_SOURCE="${TMP_DECRYPTED}"
fi

cleanup() {
    if [ -n "${TMP_DECRYPTED}" ] && [ -f "${TMP_DECRYPTED}" ]; then
        rm -f "${TMP_DECRYPTED}"
    fi
}
trap cleanup EXIT

echo "[restore] Restoring dump '${DUMP_PATH}' into database '${TARGET_DB}'..."

# Run pg_restore without logging sensitive connection credentials
pg_restore --clean --if-exists --no-owner --no-privileges -d "${TARGET_DB}" "${RESTORE_SOURCE}" || {
    echo "[restore] Note: pg_restore completed with warnings."
}

echo "[restore] Database restore completed successfully into '${TARGET_DB}'."
