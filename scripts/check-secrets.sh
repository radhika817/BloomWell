#!/usr/bin/env bash
# BloomWell Pre-Commit Hook: Secret & Forbidden File Scanner
# Fails (exit 1) if forbidden files or sensitive secret patterns are staged.

set -euo pipefail

# Ensure we are operating from the repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$REPO_ROOT"

failed=0

# 1. Inspect Staged Filenames
staged_files=$(git diff --cached --name-only --diff-filter=ACM)

if [ -n "$staged_files" ]; then
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        base=$(basename "$file")

        # Allow explicit whitelist exceptions
        if [ "$base" = ".env.example" ]; then
            continue
        fi

        # Check for forbidden files per Rule 3
        if [ "$base" = ".env" ] || [[ "$base" == .env.* ]] || [[ "$base" == *.env ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (matches .env pattern)" >&2
            failed=1
        elif [[ "$base" == *.jks ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (Java Keystore file)" >&2
            failed=1
        elif [[ "$base" == *.keystore ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (Keystore file)" >&2
            failed=1
        elif [ "$base" = "key.properties" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (key.properties file)" >&2
            failed=1
        elif [ "$base" = "google-services.json" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (google-services.json file)" >&2
            failed=1
        elif [[ "$base" == *service-account*.json ]] || [[ "$base" == *service_account*.json ]] || [[ "$base" == service-account* ]] || [[ "$base" == service_account* ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (service account credentials)" >&2
            failed=1
        elif [[ "$file" == .venv/* ]] || [[ "$file" == */.venv/* ]] || [ "$file" = ".venv" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (Python virtual environment)" >&2
            failed=1
        elif [[ "$file" == build/* ]] || [[ "$file" == */build/* ]] || [ "$file" = "build" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (build output directory)" >&2
            failed=1
        elif [[ "$file" == .dart_tool/* ]] || [[ "$file" == */.dart_tool/* ]] || [ "$file" = ".dart_tool" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (Dart tool directory)" >&2
            failed=1
        elif [[ "$file" == node_modules/* ]] || [[ "$file" == */node_modules/* ]] || [ "$file" = "node_modules" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (node_modules directory)" >&2
            failed=1
        elif [[ "$file" == postgres-data/* ]] || [[ "$file" == */postgres-data/* ]] || [ "$file" = "postgres-data" ]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (database volume data)" >&2
            failed=1
        elif [[ "$base" == *.dump ]] || [[ "$base" == *.sql ]] || [[ "$base" == *.sqlite ]] || [[ "$base" == *.sqlite3 ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (database dump/file)" >&2
            failed=1
        elif [[ "$base" == *.pdf ]]; then
            echo "❌ [check-secrets] Forbidden file staged: '$file' (generated PDF artifact)" >&2
            failed=1
        fi
    done <<< "$staged_files"
fi

# 2. Inspect Staged Text Content (added/modified lines in diff, excluding this script itself)
diff_added=$(git diff --cached -U0 --diff-filter=ACM -- . ':(exclude)scripts/check-secrets.sh' | grep -E '^\+[^+]' || true)

if [ -n "$diff_added" ]; then
    # Obvious secret pattern 1: Private key headers
    if echo "$diff_added" | grep -qE -- '-----BEGIN ([A-Z0-9_-]+ )?PRIVATE KEY-----'; then
        echo "❌ [check-secrets] Staged diff contains private key header." >&2
        failed=1
    fi

    # Obvious secret pattern 2: AWS Access Key ID (AKIA followed by 16 uppercase alphanumerics)
    if echo "$diff_added" | grep -qE -- 'AKIA[0-9A-Z]{16}'; then
        echo "❌ [check-secrets] Staged diff contains AWS Access Key ID pattern (AKIA...)." >&2
        failed=1
    fi

    # Obvious secret pattern 3: Long strings assigned to variables named secret/password/token/api_key
    if echo "$diff_added" | grep -qiE -- '([a-zA-Z0-9_-]*(secret|password|token|api_key)[a-zA-Z0-9_-]*)[[:space:]]*[:=][[:space:]]*["'"'"'][A-Za-z0-9_\-\.\+\/=]{20,}["'"'"']'; then
        echo "❌ [check-secrets] Staged diff contains long secret/password/token/api_key string assignment." >&2
        failed=1
    fi
fi

if [ "$failed" -ne 0 ]; then
    echo "🚨 [check-secrets] Pre-commit secret check failed. Please remove the secrets/forbidden files before committing." >&2
    exit 1
fi

exit 0
