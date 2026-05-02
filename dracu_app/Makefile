# Embrace Mobile RUM PoC — Makefile (obs-experiment-embrace branch)
#
# Targets the developer ergonomics for the four scenarios in
# `observability/SCENARIOS.md`. Every target degrades gracefully on
# Linux (where iOS toolchain is absent) by emitting a "skipping"
# log line rather than failing.

# ── Toolchain ───────────────────────────────────────────────────────
FLUTTER ?= flutter
MAESTRO ?= maestro

# ── Build configuration ─────────────────────────────────────────────
# API_URL points at the local Django backend by default. The
# emulator's host alias is 10.0.2.2; physical-device runs need the
# host's LAN IP. Override via `make build-android-debug API_URL=...`.
API_URL ?= http://10.0.2.2:8889

# Symbolication args — kept identical between local and CI builds so
# the dashboard's stack-trace quality matches.
RELEASE_FLAGS = --release \
                --dart-define=API_URL=$(API_URL) \
                --obfuscate \
                --split-debug-info=build/symbols

DEBUG_FLAGS = --debug --dart-define=API_URL=$(API_URL)

UNAME_S := $(shell uname -s)

.PHONY: help
help:
	@echo "Embrace Mobile RUM PoC — Makefile targets"
	@echo ""
	@echo "  build-android-debug     — debug APK with the kDebugMode crash buttons"
	@echo "  build-android-release   — release APK with R8 + Dart obfuscation"
	@echo "  build-ios-debug         — debug build (macOS only — silently skipped on Linux)"
	@echo "  build-ios-release       — release build (macOS only)"
	@echo "  upload-android-mapping  — manual fallback for Swazzler's auto-upload"
	@echo "  upload-ios-dsym         — manual dSYM upload (macOS only)"
	@echo "  test-maestro            — run all 4 Maestro flows sequentially"
	@echo "  test-maestro-baseline   — just the baseline flow"
	@echo "  test-maestro-camera     — just the camera flow"
	@echo "  test-maestro-crash      — just the crash flow"
	@echo "  test-maestro-anr        — just the ANR flow"
	@echo "  install-debug           — install the debug APK on the connected device"
	@echo "  clean                   — flutter clean + drop the build/ tree"

.PHONY: build-android-debug
build-android-debug:
	$(FLUTTER) build apk $(DEBUG_FLAGS)

.PHONY: build-android-release
build-android-release:
	@if [ ! -f android/app/src/main/embrace-config.json ]; then \
		echo "ERROR: android/app/src/main/embrace-config.json missing."; \
		echo "       cp android/app/src/main/embrace-config.json.example android/app/src/main/embrace-config.json and fill it in."; \
		exit 1; \
	fi
	$(FLUTTER) build apk $(RELEASE_FLAGS)
	@echo ""
	@echo "[Makefile] APK at build/app/outputs/flutter-apk/app-release.apk"
	@echo "[Makefile] Mapping at build/app/outputs/mapping/release/mapping.txt"
	@echo "[Makefile] Swazzler should have already uploaded the mapping;"
	@echo "[Makefile] re-run \`make upload-android-mapping\` if you don't see"
	@echo "[Makefile] '[Embrace] Uploaded mapping for ...' above."

.PHONY: build-ios-debug
build-ios-debug:
ifeq ($(UNAME_S),Darwin)
	$(FLUTTER) build ios $(DEBUG_FLAGS) --no-codesign
else
	@echo "[Makefile] SKIP build-ios-debug: iOS toolchain requires macOS (uname=$(UNAME_S))."
	@echo "[Makefile] iOS builds happen on the macos-latest runner in .github/workflows/embrace-ci.yml."
endif

.PHONY: build-ios-release
build-ios-release:
ifeq ($(UNAME_S),Darwin)
	@if [ ! -f ios/Runner/Embrace-Info.plist ]; then \
		echo "ERROR: ios/Runner/Embrace-Info.plist missing."; \
		echo "       cp ios/Runner/Embrace-Info.plist.example ios/Runner/Embrace-Info.plist and fill it in."; \
		exit 1; \
	fi
	$(FLUTTER) build ipa $(RELEASE_FLAGS)
else
	@echo "[Makefile] SKIP build-ios-release: iOS toolchain requires macOS (uname=$(UNAME_S))."
endif

.PHONY: upload-android-mapping
upload-android-mapping:
	bash observability/symbolication/upload-android-mapping.sh

.PHONY: upload-ios-dsym
upload-ios-dsym:
	bash observability/symbolication/upload-ios-dsym.sh

.PHONY: test-maestro
test-maestro: test-maestro-baseline test-maestro-camera test-maestro-crash test-maestro-anr

.PHONY: test-maestro-baseline
test-maestro-baseline:
	$(MAESTRO) test observability/load-test/maestro-baseline.yaml

.PHONY: test-maestro-camera
test-maestro-camera:
	$(MAESTRO) test observability/load-test/maestro-camera.yaml

.PHONY: test-maestro-crash
test-maestro-crash:
	$(MAESTRO) test observability/load-test/maestro-crash.yaml

.PHONY: test-maestro-anr
test-maestro-anr:
	$(MAESTRO) test observability/load-test/maestro-anr.yaml

.PHONY: install-debug
install-debug: build-android-debug
	$(FLUTTER) install --debug

.PHONY: clean
clean:
	$(FLUTTER) clean
	rm -rf build/symbols
