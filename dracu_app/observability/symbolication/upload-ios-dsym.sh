#!/usr/bin/env bash
#
# Manual fallback for iOS dSYM upload.
#
# Normally an Xcode build phase (added to ios/Runner.xcodeproj on
# this branch — see ios/scripts/upload-symbols.sh) auto-uploads the
# Runner.app.dSYM bundle after every Release build. Reasons this
# script might be needed:
#
#   * Symbolicating a build produced by an old branch / before the
#     run-script phase was wired.
#   * The Xcode build host had no network access during the build
#     phase (the script there logs a warning and exits 0).
#   * Re-uploading a dSYM after rotating Embrace creds.
#
# Hard requirement: macOS host. dSYM bundles are produced by Xcode +
# the iOS toolchain; they cannot be generated on Linux. We gate the
# whole script on `uname == Darwin` so a Linux dev who runs it gets
# a clear "skipped" message instead of a confusing curl failure.

set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
    echo "[upload-ios-dsym] SKIP: this script requires macOS (Xcode + dSYM tooling)." >&2
    echo "[upload-ios-dsym]   On Linux, iOS symbol uploads run from CI (.github/workflows/embrace-ci.yml job 'ios')." >&2
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

CONFIG="$APP_DIR/ios/Runner/Embrace-Info.plist"
if [[ -z "${APP_ID:-}" || -z "${API_TOKEN:-}" ]]; then
    if [[ ! -f "$CONFIG" ]]; then
        echo "[upload-ios-dsym] ERROR: $CONFIG not found and APP_ID/API_TOKEN not set." >&2
        echo "[upload-ios-dsym]   cp Embrace-Info.plist.example Embrace-Info.plist and fill it in." >&2
        exit 1
    fi
    # PlistBuddy ships with macOS — guaranteed to be available on a
    # darwin host since we already gated on uname.
    APP_ID="${APP_ID:-$(/usr/libexec/PlistBuddy -c 'Print :EMBRACE_APP_ID' "$CONFIG")}"
    API_TOKEN="${API_TOKEN:-$(/usr/libexec/PlistBuddy -c 'Print :EMBRACE_API_TOKEN' "$CONFIG")}"
fi

if [[ "$APP_ID" == "REPLACE_ME"* || "$API_TOKEN" == "REPLACE_ME"* ]]; then
    echo "[upload-ios-dsym] ERROR: APP_ID/API_TOKEN still hold placeholder values." >&2
    exit 1
fi

# ── Resolve dSYM bundle ─────────────────────────────────────────────
DSYM="${1:-}"
if [[ -z "$DSYM" ]]; then
    # Default xcodebuild output path. archive-build vs build give
    # different layouts; we look for both.
    CANDIDATES=(
        "$APP_DIR/build/ios/Release-iphoneos/Runner.app.dSYM"
        "$APP_DIR/build/ios/archive/Runner.xcarchive/dSYMs/Runner.app.dSYM"
        "$APP_DIR/build/ios/iphoneos/Runner.app.dSYM"
    )
    for c in "${CANDIDATES[@]}"; do
        if [[ -d "$c" ]]; then
            DSYM="$c"
            break
        fi
    done
fi

if [[ -z "$DSYM" || ! -d "$DSYM" ]]; then
    echo "[upload-ios-dsym] ERROR: Runner.app.dSYM not found." >&2
    echo "[upload-ios-dsym]   Tried: ${CANDIDATES[*]}" >&2
    echo "[upload-ios-dsym]   Run \`flutter build ipa --release\` first." >&2
    exit 1
fi

# ── Zip dSYM (Embrace expects a single file upload, not a dir) ─────
TMP_ZIP="$(mktemp -t embrace-dsym).zip"
trap "rm -f '$TMP_ZIP'" EXIT

(cd "$(dirname "$DSYM")" && zip -qry "$TMP_ZIP" "$(basename "$DSYM")")

VERSION_NAME="${VERSION_NAME:-$(grep -E '^version: ' "$APP_DIR/pubspec.yaml" | sed -E 's/version: *([^+]+).*/\1/' | tr -d ' ')}"
VERSION_NAME="${VERSION_NAME:-1.0.0}"
VERSION_CODE="${VERSION_CODE:-1}"

echo "[upload-ios-dsym] app_id=$APP_ID  versionName=$VERSION_NAME  versionCode=$VERSION_CODE"
echo "[upload-ios-dsym] dsym=$DSYM (zipped to $TMP_ZIP, $(du -k "$TMP_ZIP" | cut -f1) KiB)"

curl --fail-with-body -sS \
    -X POST "https://api.emb-api.com/api/v2/sdk/symbols" \
    -H "X-EM-AID: $APP_ID" \
    -H "X-EM-TOKEN: $API_TOKEN" \
    -F "app=ios" \
    -F "version_name=$VERSION_NAME" \
    -F "version_code=$VERSION_CODE" \
    -F "type=dsym" \
    -F "file=@$TMP_ZIP"

echo
echo "[upload-ios-dsym] OK."
