#!/usr/bin/env bash
#
# Manual fallback for Android R8/Dart symbolication.
#
# Normally the Embrace Swazzler auto-uploads `mapping.txt` after every
# `flutter build apk --release` (look for the `[Embrace] Uploaded
# mapping for ...` line in the gradle output). Reasons this script
# might be needed:
#
#   * The CI runner had no network access during `assembleRelease`
#     (Swazzler swallows the error and exits 0 — by design).
#   * The mapping was generated outside `flutter build` (e.g. via a
#     standalone `./gradlew assembleRelease` invocation) and the
#     Swazzler post-task didn't run.
#   * You're symbolicating an OLD release post-mortem.
#
# Idempotent: re-uploading the same mapping for the same
# `versionCode` overwrites the previous one server-side.
#
# Usage:
#   ./upload-android-mapping.sh                         # auto-detect everything
#   ./upload-android-mapping.sh path/to/mapping.txt     # explicit mapping
#   APP_ID=... API_TOKEN=... ./upload-android-mapping.sh ...   # explicit creds
#
# Requires `curl` and a GNU-compatible `find`. Pure POSIX-ish bash —
# does not require the Android SDK or gradle.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Resolve credentials ─────────────────────────────────────────────
CONFIG="$APP_DIR/android/app/src/main/embrace-config.json"
if [[ -z "${APP_ID:-}" || -z "${API_TOKEN:-}" ]]; then
    if [[ ! -f "$CONFIG" ]]; then
        echo "[upload-android-mapping] ERROR: $CONFIG not found and APP_ID/API_TOKEN not set." >&2
        echo "[upload-android-mapping]   cp embrace-config.json.example embrace-config.json and fill it in." >&2
        exit 1
    fi
    # Tiny embedded jq-substitute so we don't depend on jq.
    APP_ID="${APP_ID:-$(python3 -c "import json; print(json.load(open('$CONFIG'))['app_id'])")}"
    API_TOKEN="${API_TOKEN:-$(python3 -c "import json; print(json.load(open('$CONFIG'))['api_token'])")}"
fi

if [[ "$APP_ID" == "REPLACE_ME"* || "$API_TOKEN" == "REPLACE_ME"* ]]; then
    echo "[upload-android-mapping] ERROR: APP_ID/API_TOKEN still hold placeholder values." >&2
    exit 1
fi

# ── Resolve mapping.txt ─────────────────────────────────────────────
MAPPING="${1:-}"
if [[ -z "$MAPPING" ]]; then
    # Default location after `flutter build apk --release`
    MAPPING="$APP_DIR/build/app/outputs/mapping/release/mapping.txt"
fi

if [[ ! -f "$MAPPING" ]]; then
    echo "[upload-android-mapping] ERROR: mapping.txt not found at $MAPPING" >&2
    echo "[upload-android-mapping]   Run \`flutter build apk --release\` first (and confirm minifyEnabled = true)." >&2
    exit 1
fi

# ── Resolve versionCode (mandatory for the upload payload) ──────────
GRADLE_FILE="$APP_DIR/android/app/build.gradle"
LOCAL_PROPS="$APP_DIR/android/local.properties"

VERSION_CODE="${VERSION_CODE:-}"
if [[ -z "$VERSION_CODE" && -f "$LOCAL_PROPS" ]]; then
    VERSION_CODE="$(grep -E '^flutter\.versionCode=' "$LOCAL_PROPS" | cut -d= -f2 || true)"
fi
VERSION_CODE="${VERSION_CODE:-1}"

VERSION_NAME="${VERSION_NAME:-$(grep -E '^version: ' "$APP_DIR/pubspec.yaml" | sed -E 's/version: *([^+]+).*/\1/' | tr -d ' ')}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"

echo "[upload-android-mapping] app_id=$APP_ID  versionName=$VERSION_NAME  versionCode=$VERSION_CODE"
echo "[upload-android-mapping] mapping=$MAPPING ($(wc -l < "$MAPPING") lines)"

# Embrace's symbol upload endpoint. Documented at
# https://embrace.io/docs/embrace-api-docs/#section/Symbol-Files
curl --fail-with-body -sS \
    -X POST "https://api.emb-api.com/api/v2/sdk/symbols" \
    -H "X-EM-AID: $APP_ID" \
    -H "X-EM-TOKEN: $API_TOKEN" \
    -F "app=android" \
    -F "version_name=$VERSION_NAME" \
    -F "version_code=$VERSION_CODE" \
    -F "type=proguard" \
    -F "file=@$MAPPING"

echo
echo "[upload-android-mapping] OK."
