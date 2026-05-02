#!/usr/bin/env bash
#
# Xcode build-phase script — add to the Runner target's Build Phases
# AFTER the "Embed Frameworks" phase so the dSYM exists at the
# expected path when this runs. Open Runner.xcworkspace > Runner
# target > Build Phases > "+" (top-left) > New Run Script Phase >
# paste the line below into the script editor (NOT this whole file —
# Xcode build phases are inline shell, not script paths):
#
#     "${SRCROOT}/scripts/upload-symbols.sh"
#
# (We keep the file here so it lives in version control and so the CI
# workflow can invoke it explicitly outside of an Xcode build.)
#
# Skipped silently for Debug builds. Skipped with a logged warning if
# Embrace-Info.plist holds placeholder values (so a developer who
# checked out the repo for the first time doesn't hit a build failure
# before they've had a chance to fill in their app_id).

set -euo pipefail

# ── Skip non-Release builds ─────────────────────────────────────────
# Embrace's symbolication tooling only meaningfully applies to
# obfuscated/optimised release builds. Debug builds don't strip
# symbols so the dashboard already shows readable frames.
if [[ "${CONFIGURATION:-}" != "Release" ]]; then
    echo "[Embrace] Skipping dSYM upload (CONFIGURATION=$CONFIGURATION, expected Release)."
    exit 0
fi

PLIST="${SRCROOT}/Runner/Embrace-Info.plist"
if [[ ! -f "$PLIST" ]]; then
    echo "warning: [Embrace] Embrace-Info.plist not found at $PLIST — skipping dSYM upload."
    exit 0
fi

APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :EMBRACE_APP_ID' "$PLIST" 2>/dev/null || echo '')"
API_TOKEN="$(/usr/libexec/PlistBuddy -c 'Print :EMBRACE_API_TOKEN' "$PLIST" 2>/dev/null || echo '')"

if [[ -z "$APP_ID" || "$APP_ID" == "REPLACE_ME"* ]]; then
    echo "warning: [Embrace] EMBRACE_APP_ID is unset or placeholder — skipping dSYM upload."
    exit 0
fi

# ── Locate the dSYM bundle ──────────────────────────────────────────
# Xcode places it at $DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME for
# both archive and direct-build paths.
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"

if [[ ! -d "$DSYM_PATH" ]]; then
    echo "warning: [Embrace] dSYM not found at $DSYM_PATH — confirm DEBUG_INFORMATION_FORMAT = 'DWARF with dSYM File' in Build Settings."
    exit 0
fi

VERSION_NAME="${MARKETING_VERSION:-1.0.0}"
VERSION_CODE="${CURRENT_PROJECT_VERSION:-1}"

# Delegate the actual zip-and-curl to the same script the manual
# fallback uses, so behaviour stays identical between local Xcode
# builds and `make upload-ios-dsym`.
APP_ID="$APP_ID" API_TOKEN="$API_TOKEN" \
    VERSION_NAME="$VERSION_NAME" VERSION_CODE="$VERSION_CODE" \
    "${SRCROOT}/../observability/symbolication/upload-ios-dsym.sh" "$DSYM_PATH"
