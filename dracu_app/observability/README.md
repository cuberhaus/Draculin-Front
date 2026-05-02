# Embrace Mobile RUM PoC — `Draculin-Front/dracu_app`

Standalone PoC on the `obs-experiment-embrace` branch in BOTH
[`Draculin-Front`](../../) and [`Draculin-Backend`](../../../Draculin-Backend/).

Embrace is the only stack in the portfolio whose **primitive is a
user session, not a span** — that mental-model gap is the whole
point of this experiment. See
[`dev/observability_architectures_summary.md`](../../../dev/observability_architectures_summary.md)
for the cross-stack comparison context.

## Scope

| Aspect | Decision |
|---|---|
| Vendor | Embrace (SaaS-only, free tier 5K MAU, no self-hosted option) |
| Platforms | **Android + iOS only**. Flutter Web is dropped — Embrace's Flutter SDK doesn't ship a web target. |
| Iframe build | The web-target iframe at [`Draculin-Front/Dockerfile`](../../Dockerfile) is **untouched** on this branch; the parent portfolio's Sentry-Astro still covers the iframe wrapper. |
| Sentry | **Deleted** from both `Draculin-Front` (was only inherited transitively) and `Draculin-Backend` (the helper at `Draculin/_sentry_obs.py` and the middleware reference). The PoC is pure mobile-RUM, not Sentry+Embrace. |
| Backend | **Opaque on this branch** — Django has zero observability. That is the honest mobile-RUM mental model: most mobile teams don't own the backend they call. Documented as a feature, not a bug. See [`Draculin-Backend/observability/README.md`](../../../Draculin-Backend/observability/README.md). |
| iOS local builds | Not possible on Linux (the dev box). iOS code is committed and CI-built (GitHub Actions `macos-latest` job in [`.github/workflows/embrace-ci.yml`](../../.github/workflows/embrace-ci.yml)) but locally only Android is verifiable. |

## Repo layout

```
dracu_app/
  lib/
    main.dart                          # MODIFIED: Embrace boot, breadcrumbs, personas, http client wiring
    observability/
      embrace.dart                     # facade: breadcrumb / log / span / persona / record-net
      embrace_http_client.dart         # http.BaseClient wrapper, injects X-Embrace-Session-Id
    debug/
      crash_button.dart                # kDebugMode-only screen with 3 FAB triggers
  android/
    settings.gradle                    # (vanilla)
    build.gradle                       # MODIFIED: classpath io.embrace:embrace-swazzler
    app/
      build.gradle                     # MODIFIED: apply 'embrace-swazzler', minSdk 23, R8
      proguard-rules.pro               # NEW: -keep io.embrace.** + Flutter + camera plugin
      src/main/
        AndroidManifest.xml            # MODIFIED: android:name=".DracuApplication"
        kotlin/com/example/dracu_app/
          DracuApplication.kt          # NEW: Embrace.getInstance().start(this) in onCreate
          MainActivity.kt              # (unchanged)
        embrace-config.json            # GITIGNORED: real APP_ID + API_TOKEN
        embrace-config.json.example    # NEW: template
  ios/
    Runner/
      AppDelegate.swift                # MODIFIED: Embrace.setup().start() in init()
      Info.plist                       # (unchanged)
      Embrace-Info.plist               # GITIGNORED: real APP_ID + API_TOKEN
      Embrace-Info.plist.example       # NEW: template
    scripts/
      upload-symbols.sh                # NEW: Xcode build-phase script for dSYM upload (Release only)
  observability/
    README.md                          # this file
    SCENARIOS.md                       # 4 scenarios — cold-start regression, network failure spike, crash, ANR
    .env.embrace.example               # APP_ID + API_TOKEN slot template
    load-test/
      maestro-baseline.yaml            # exercises every screen, foreground/background flush
      maestro-camera.yaml              # 5x camera-capture loop for percentile histograms
      maestro-crash.yaml               # debug-build only — drives the Dart-exception button
      maestro-anr.yaml                 # debug-build only — drives the 6s busy-wait button
    symbolication/
      upload-android-mapping.sh        # manual fallback when Swazzler post-build hook fails
      upload-ios-dsym.sh               # macOS-gated; zip + POST Runner.app.dSYM
  Makefile                             # NEW: build/test/upload targets, Linux-aware
  pubspec.yaml                         # MODIFIED: embrace ^4.6.0, embrace_android, embrace_ios
  README.md                            # (vanilla Flutter starter — left as-is)
```

## Quick-start (Android, the locally verifiable path)

1. **Create an Embrace account** at <https://dash.embrace.io/>
   (free tier requires email, no credit card). Create a project,
   note the 12-char hex `app_id` and 32-char hex `api_token`.

2. **Materialise the config**:

   ```bash
   cd android/app/src/main
   cp embrace-config.json.example embrace-config.json
   $EDITOR embrace-config.json   # paste app_id + api_token
   ```

3. **Verify Flutter ≥ 3.27**:

   ```bash
   flutter --version
   # Flutter 3.27.0 or newer required
   ```

   If older, follow <https://docs.flutter.dev/release/upgrade>.

4. **Boot an Android emulator** (or plug in a USB device with
   developer mode + USB debugging enabled). On Linux:

   ```bash
   # Verify KVM is available (one-shot)
   grep -c -E '^flags.*(vmx|svm)' /proc/cpuinfo
   # > 0 means hardware virtualisation is on; emulator will be fast.

   # List + start emulators (Android Studio's AVD Manager is the easy path)
   ~/Android/Sdk/emulator/emulator -list-avds
   ~/Android/Sdk/emulator/emulator -avd Pixel_7_API_34 &
   ```

5. **Install + run the debug build**:

   ```bash
   make build-android-debug install-debug
   # OR equivalently:
   flutter run --debug --dart-define=API_URL=http://10.0.2.2:8889
   ```

6. **Foreground/background the app** a couple of times. The
   first session payload uploads on background. Refresh the
   Embrace dashboard at dash.embrace.io — you should see the
   session within ~60 s under "Sessions".

## Quick-start (iOS, CI-only path on Linux)

You can't build iOS on Linux. Two options:

* Push to the `obs-experiment-embrace` branch — the
  `ios` job in `.github/workflows/embrace-ci.yml` builds the
  IPA on `macos-latest` and uploads the dSYM to Embrace.
* On a macOS box: `make build-ios-debug` and `make upload-ios-dsym`.

## Embrace dashboard tour

The dashboard is laid out around the **session** primitive:

| Panel | What you'll see | Useful for |
|---|---|---|
| **Sessions** | One row per app foreground. Click a row → full breadcrumb timeline + network requests + logs + crash (if any). | Triaging "what did this user do before X happened". |
| **Crashes** | Grouped by stack signature. Click a group → all sessions that hit it. | Symbolication discipline check (frames should be readable). |
| **Network** | All HTTP requests grouped by URL pattern. Per-pattern p50/p95/p99 + error rate. | Verifying the `DracuHttpClient` wrapper (which composes the SDK's `EmbraceHttpClient` as inner) is recording every endpoint. |
| **Performance** | Custom Performance Traces. Look for `camera_capture` with its 3 child spans (compress / upload / parse_response). | Verifying the Phase 4 nested spans render. |
| **App Startup** | Cold-start time histogram, segments by app version. | Scenario 1 (cold-start regression) lives here. |
| **ANRs / App Hangs** | Application-Not-Responding events with main-thread stacks. | Scenario 4 (ANR) lives here. |
| **Personas** | Sessions filtered by user persona. Should show `returning` and `power-user` after enough launches. | Verifying the Phase 4 launch-counter logic. |
| **Logs** | Free-form messages logged via `DracuObs.info/warn/error`. | Tracing intentional fallbacks (e.g. "chat: server returned non-2xx"). |

## Where-to-click for each scenario

See [`SCENARIOS.md`](SCENARIOS.md). Each scenario's "Where to
click in the dashboard" section names the panel + the filter
to apply.

## Caveats and known limitations

1. **Backend opacity is by design.** The Django backend has no
   observability on this branch (Sentry deleted). Failures
   originating server-side surface in the Embrace dashboard as
   "API returned 5xx from `/api/X/`" with zero server context.
   This IS the lesson of mobile RUM. See
   [`Draculin-Backend/observability/README.md`](../../../Draculin-Backend/observability/README.md).
2. **Embrace SaaS lock-in is irreversible.** No self-hosted
   option, no data export API, no "downgrade to OSS" path.
   Documented in the cross-architecture trade-offs row.
3. **R8/Proguard symbolication race.** The Swazzler uploads
   `mapping.txt` post-build. If the upload fails (network blip,
   bad token), crashes show un-deobfuscated frames. Manually
   re-upload with `make upload-android-mapping`.
4. **iOS coverage is committed-but-not-locally-tested.** All
   iOS code is in the repo and CI-built, but the dev box is
   Linux-only.
5. **Camera permission on emulator.** The DracuVision screen
   uses the device camera. Android emulator's virtual camera
   produces a black frame; the backend's image-processing
   endpoint may return an error. Acceptable — the PoC validates
   timing capture, not the ML output.
6. **Render.com baseline backend.** The Flutter app's
   `defaultValue` for `API_URL` points at
   `https://bits-draculin.onrender.com`. Local PoC verification
   uses `--dart-define=API_URL=http://10.0.2.2:8889` (Android
   emulator's host-localhost alias). Documented in the Makefile.
7. **Flutter Web is intentionally absent.** Embrace ships no
   web SDK. The iframe Dockerfile build at
   `Draculin-Front/Dockerfile` is unchanged on this branch and
   will fail to find an `embrace_web` package — that's expected;
   Embrace's pub package resolves the platform plugins as no-ops
   on web.
8. **`embrace` 4.6.0 is the latest published version on
   pub.dev as of writing.** The plan referenced "Embrace v6+"
   based on native SDK release numbers (Android SDK 6.x, iOS SDK
   6.x); the **Flutter wrapper** is on its own version line at
   4.x. Don't try to pin `embrace: ^6.0.0` — it doesn't exist.
