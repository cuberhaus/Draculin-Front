# Scripted scenarios — Embrace Mobile RUM PoC

These four scenarios produce comparable observations across all
mobile-vs-server PoCs in the portfolio. Run each, capture
screenshots from the Embrace dashboard, write up findings in
`obs-experiment-notes.md` at the repo root.

The expectation is **not** that Embrace "wins" against the LGTM /
Honeycomb / Coroot / Elastic stacks — those are server-side
products instrumented with very different mental models. The
point is to make the **trade-offs** concrete: Embrace's primitive
is a user session, not a span, and these scenarios deliberately
exercise the things that buys you (and the things it costs).

All four scenarios are driven by Maestro flows under
[`load-test/`](load-test/). Each flow is one YAML file,
runnable on Android emulator with `make test-maestro` (which
ultimately calls `maestro test load-test/<flow>.yaml`).

> **Backend-opacity reminder**: with Sentry deleted from
> `Draculin-Backend` on this branch, the Django backend has zero
> server-side observability. Every scenario below assumes you're
> looking at the failure FROM THE MOBILE SIDE. The backend's
> behaviour is a black box — that's the honest mobile-RUM mental
> model and the lesson scenario #2 makes explicit.

## Pre-flight

1. Embrace SaaS account exists; `embrace-config.json` (Android)
   and `Embrace-Info.plist` (iOS) hold the real `app_id` /
   `api_token` from dash.embrace.io. See `README.md`.
2. Android emulator running (or physical device over USB).
3. Django backend running locally on `:8889`. (For scenarios
   1, 3, 4 the backend can be down — the flows tolerate it. For
   scenario 2, you'll deliberately kill it mid-flow.)
4. Build flavour:
   * Scenarios 1, 2 → debug build is fine
   * Scenarios 3, 4 → use `make build-android-release` so the
     R8/Dart obfuscation is exercised and the dashboard's
     symbolicated-vs-mangled distinction is observable.

## Scenario 1 — Cold-start regression

**Setup**: insert a synthetic 600 ms `await Future.delayed` in
`_MyAppState.initState`. Embrace's "App Startup Time" panel
should shift; the regression is visible per app version.

Patch (revert when done):

```dart
// SCENARIO 1 — remove when capture is done.
@override
void initState() {
  super.initState();
  Future.delayed(const Duration(milliseconds: 600));  // synthetic regression
  ...
}
```

**Drive load**: `maestro test observability/load-test/maestro-baseline.yaml`
once before the patch and once after. Each flow does 5 cold
starts in a row (foreground → background → foreground), giving
Embrace enough samples to materialise the median shift.

**Comparison axes** vs. the other PoCs:

| Question | Embrace answer | LGTM/Coroot/Elastic answer |
|---|---|---|
| Is "cold start" a first-class metric? | Yes — dedicated panel, always-on, segments by app version. | No — would have to manufacture it from the first OTel span emitted by the runtime. None of the four ship a cold-start panel out of the box. |
| Time from regression to noticing it? | One refresh of the Sessions tab; the panel shows a step-change. | N/A — none of the others would surface this without bespoke instrumentation. |
| Per-version comparison? | Built-in: dropdown filter on "App Version". | Possible via OTel's `service.version` attribute but requires manual dashboard work. |
| Does it survive a release rollback? | Yes — the panel keeps the version's historical data. | N/A. |

**Where to click in the dashboard**:
Sessions → Performance → App Startup Time → group by App Version.

## Scenario 2 — Network failure spike (backend dies mid-session)

**Setup**: while a Maestro flow is in the middle of exercising
DracuChat / DracuVision / DracuNews, kill the local Django
backend with `Ctrl-C`. Every subsequent HTTP request from the
app fails with a transport error (connection refused on
emulator's `10.0.2.2:8889`).

**Drive load**:

```bash
# Terminal 1 — backend
cd ../Draculin-Backend && python manage.py runserver 0.0.0.0:8889

# Terminal 2 — Maestro
cd Draculin-Front/dracu_app
maestro test observability/load-test/maestro-baseline.yaml &
sleep 8           # let it complete DracuNews fetch
kill -INT %1       # kill the backend (Terminal 1's runserver)
wait              # let the rest of the flow run against a dead backend
```

**Expected in Embrace dashboard** (within ~60 s of session
end / app background):

* The Network tab shows a cluster of failed requests under each
  endpoint pattern (`/api/news/`, `/api/chat/`, `/api/camera/`)
  with `error_type = SocketException` (or similar transport-level
  exception name).
* The Sessions tab marks the affected session as "frustrated"
  (Embrace's UX-frustration heuristic — high error rate within
  one session).
* The Logs tab shows the WARN-level log lines emitted by
  `_sendMessage` ("chat: server returned non-2xx") AND
  the ERROR breadcrumb ("chat: send failed (SocketException)")
  immediately preceding each failure.

**Comparison axes** vs. the other PoCs:

| Question | Embrace answer | Server-side PoCs (LGTM/Coroot/Elastic) |
|---|---|---|
| Did the failure show up at all? | Yes — every failure surfaces in the Network tab. | No — the backend is dead; there's no server-side telemetry of failures at the level of "this user got a 500". |
| Per-user blast radius? | Yes — "this user had 5 consecutive failures". | No — only "API error rate spiked", no per-user attribution. |
| Was the request retried? | Visible because each retry is a separate Network event with its own timestamp. | Same as above. |
| What did the user do AFTER the failure? | Visible — the breadcrumb timeline shows their next nav action. | No equivalent. |

**The lesson**: Embrace sees the failure that the server stack
literally cannot see (because the server isn't running). This
is the canonical mobile RUM differentiator — failures originate
on the device, traverse the network, may never reach the
server. Server-side stacks are blind to that whole class.

**Where to click in the dashboard**: Network → 4xx/5xx tab → group by URL Pattern.

## Scenario 3 — Deliberate Dart crash

**Setup**: tap the debug "Throw Dart Exception" button on the
hidden 6th nav tab (`kDebugMode` only). The runZonedGuarded
that `Embrace.installErrorHandlers` wrapped in `main.dart`
catches the StateError and forwards it to Embrace as an
unhandled crash.

**Drive load**:

```bash
maestro test observability/load-test/maestro-crash.yaml
```

The flow: open app → wait for cold start → tap nav tab "Debug"
→ tap "Throw Dart Exception" → the app dies → Maestro detects
the dead app and exits with code 0.

**Expected in Embrace dashboard** (within ~60 s of next app
launch — Embrace uploads crash payloads on the NEXT start, not
in real time):

* Crashes tab shows a new entry: "StateError: Intentional crash
  from Embrace verification harness".
* The stack trace (in a release build) shows real Dart class /
  method names: `_throwDartException`, `CrashButtonScreen.build`,
  `MaterialApp.build`, ...
* If the build was NOT release-with-symbols, the stack frames
  will look like `aQ5#1`, `bM2#3` — that's the symbolication
  pipeline failing visibly. Re-run with
  `make build-android-release` and re-upload the mapping.txt
  via `make upload-android-mapping`.
* The breadcrumb timeline preceding the crash shows
  "nav: Debug" then "debug: about to throw Dart exception".

**Comparison axes** vs. server-side PoCs:

| Question | Embrace answer | LGTM / Coroot / Elastic |
|---|---|---|
| Did the crash get captured? | Yes. | No — the app crashed before any server request was even attempted. None of the four would know this happened. |
| Time from crash to dashboard visibility? | ~60 s after next app launch. | N/A. |
| Stack trace quality | Symbolicated Dart frames + native frames. | N/A. |
| User context (what nav, what screen, what session)? | Full session breadcrumb timeline + persona tag. | N/A. |

**Where to click in the dashboard**: Crashes → group by Stack Signature → click the new entry.

## Scenario 4 — ANR (Application Not Responding)

**Setup**: tap the debug "ANR" button. The handler busy-waits on
the main isolate for 6 seconds. Android's WatchDog raises ANR
at the 5-s mark; the OS shows the "App Not Responding" dialog
to the user and Embrace's ANR detector samples the main thread
stack at the moment the freeze became visible to the OS.

**Drive load**:

```bash
maestro test observability/load-test/maestro-anr.yaml
```

The flow: open app → wait for cold start → tap nav tab "Debug"
→ tap "ANR (6s main-thread sleep)" → Maestro waits 8 s → resumes
or kills the app.

**Expected in Embrace dashboard** (within ~60 s):

* The session payload contains an `application_not_responding`
  event with a stack trace showing the busy-wait loop in
  `_triggerAnr` at the moment of detection.
* The Sessions tab marks the session as having an ANR; the
  ANR-rate metric on the dashboard's main page ticks up.
* The breadcrumb trail shows "nav: Debug" then
  "debug: pegging main thread for 6s (ANR)".

**iOS equivalent**: "App Hang". Only fires on iOS-built
artefacts. The Maestro flow doesn't run on iOS from this
Linux dev box; the equivalent capture is exercised in CI by
the `ios` job in `.github/workflows/embrace-ci.yml`.

**Comparison axes** vs. server-side PoCs:

| Question | Embrace answer | LGTM / Coroot / Elastic |
|---|---|---|
| Is ANR a first-class signal? | Yes — separate metric, separate alert, separate dashboard panel. | No — ANR is a UI-thread concept; server-side stacks have no UI thread. |
| Stack at the moment of detection? | Yes — Embrace samples the main thread every 100 ms during the freeze. | N/A. |
| Per-version ANR rate? | Yes — "ANR Rate" metric segments by app version. | N/A. |
| Cost to surface this in a different stack? | N/A. | High — would require shipping an APM agent that knows about Android's WatchDog. None of the four ship one. |

**Where to click in the dashboard**: Sessions → ANR Rate → group by App Version.

## Reverting the scenarios

Scenarios 1 (cold-start regression) edits `lib/main.dart` —
revert with `git checkout lib/main.dart` once observations are
captured. Scenarios 2, 3, 4 require no source-code changes
(scenario 2 is a runtime kill, scenarios 3 & 4 use the
debug-build harness in `lib/debug/crash_button.dart`).

## Optional: lift to make targets

Once the four scenarios stabilise, the `Makefile` already wires
`make test-maestro` to run all four sequentially. CI runs them
on the `android` job (post-build) — see `embrace-ci.yml`.

## Where to find the screenshots

After running each scenario, save dashboard screenshots into
`docs/screenshots/embrace/scenario-<N>-<panel>.png` and
reference them inline in
[`../obs-experiment-notes.md`](../obs-experiment-notes.md) at
the repo root, alongside the equivalent capture for each of the
other PoCs.
