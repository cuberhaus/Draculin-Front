# Embrace Mobile RUM PoC — observation log

Fill this in as you actually use the Embrace dashboard. The
Coroot (`subgrup-prop7.1`), Honeycomb (`pracpro2`), and LGTM
(`Practica_de_Planificacion`) PoCs have their own version of
this file with the same headings, so a `diff` across the four
is the fastest comparison medium.

Cells filled with concrete numbers below come from the Phase
0–6 implementation work (the engineering was real). Cells
marked TBD are reserved for hands-on UX observations once the
four scenarios in
[`dracu_app/observability/SCENARIOS.md`](dracu_app/observability/SCENARIOS.md)
actually run on a device with live Embrace credentials.

---

## First impressions

_Notes from the first 30 minutes of clicking around the
Embrace dashboard after the first session lands. What stood
out, what was confusing, what was surprisingly fast or slow._

- **Time from `make build-android-debug install-debug` to first
  session in dashboard:** TBD. Expected ~60 s based on the
  Embrace docs (the SDK uploads on first background → foreground
  cycle). The flow: launch app on emulator → tap through
  DracuNews → press Home → re-launch → check dashboard.
- **Time from first session to first useful query:** TBD. Embrace's
  UI is opinionated (no query language); the "useful query" is
  whichever pre-built panel surfaces the metric you care about
  first.
- **Friction points (hit during Phase 0–5 implementation):**
  1. **Embrace Flutter SDK is on its own version line.** The plan
     referenced "Embrace v6+" based on native SDK numbers; the
     **Flutter wrapper** is at 4.6.0. Misleading if you go straight
     from the Android docs.
  2. **`Embrace.instance.start`'s `action` parameter has wandered
     between positional and named** between SDK versions. The
     official integration docs example
     (`await Embrace.instance.start(() => runApp(...));`) is
     positional; the auto-generated API reference shows it as
     named (`{FutureOr action()?}`). The clean alternative is
     `await Embrace.instance.start();` followed by
     `await Embrace.instance.installErrorHandlers(() => runApp(MyApp()));`
     — unambiguous and forward-compatible. Used in `lib/main.dart`.
  3. **Native bootstrap is required on BOTH Android and iOS.** The
     Dart-side `Embrace.instance.start()` alone doesn't capture
     native crashes during Flutter cold start. Required:
     `DracuApplication.kt` extending `Application` with
     `Embrace.getInstance().start(this)` in `onCreate`, AND
     `AppDelegate.swift` with `try Embrace.setup(...).start()` in
     `init()`. The Embrace Flutter SDK's docs cover this but the
     "just add a Dart call" mental model misses it.
  4. **Swazzler uses the legacy `apply plugin:` syntax**, not the
     modern `id` syntax in the `plugins {}` block of
     `app/build.gradle`. The classpath dep goes in the root
     `buildscript` block. Mixing them is fine, but the modern-style
     intuition wastes 30 minutes if you assume the Swazzler is a
     normal Gradle plugin.
  5. **Backend opacity is unsettling at first.** With Sentry
     deleted from `Draculin-Backend`, when the app records a
     500 from `/api/chat/`, you have **zero** server-side context.
     The first instinct is "let me check the Sentry dashboard for
     the matching server error" — there is no Sentry dashboard.
     This is the lesson, but it's worth surfacing in this notes
     file because future-me will forget.

## Cold-start regression UX (Scenario 1)

_See [SCENARIOS.md → Scenario 1](dracu_app/observability/SCENARIOS.md#scenario-1--cold-start-regression).
Capture time-to-detection, number of clicks from "is this
release slower?" to "by how much, on which device", and any
moment where Embrace's UI made the diagnosis faster or slower
than expected._

- **Time from regression to noticing:** TBD. Embrace's "App
  Startup Time" panel is the prebuilt place to look; expected
  ~1 dashboard refresh after the first session of the slowed
  build lands.
- **Clicks from "this release is slower" → "by how much":**
  TBD — the App Startup panel ships with version-segmented
  histograms by default; should be 0 clicks (just look).
- **Did you spot the 600 ms shift on a single device, or did it
  need to be averaged across multiple sessions?** TBD. Embrace
  shows per-session times so a single repro session is enough,
  but the panel headline number is a median.
- **Could you compare two releases side-by-side without
  building a custom dashboard?** TBD — expected yes via the
  built-in version dropdown.

## Network-failure-spike UX (Scenario 2 — backend opacity demo)

_See [SCENARIOS.md → Scenario 2](dracu_app/observability/SCENARIOS.md#scenario-2--network-failure-spike-backend-dies-mid-session)._

- **Time from backend-dies to "Embrace shows me a session full
  of failures":** TBD. Failures land per-request in the Network
  tab; expected to surface immediately on session-end (i.e. on
  the first foreground/background cycle after the failures
  start).
- **Per-user blast radius visible?** Expected yes — Embrace's
  primitive is the session, so "this user's session contained
  5 consecutive transport failures" is a single-row finding.
- **What server context is available for the 500s?** **None.**
  Sentry is deleted from `Draculin-Backend` on this branch, so
  the Embrace dashboard knows the request failed but has zero
  knowledge of why. Document this concretely with a screenshot
  of the Network panel showing the failed request alongside an
  empty "Server-side context" panel.
- **Did the WARN log line + ERROR breadcrumb (added in Phase 4)
  give enough context to triage from the mobile side alone?**
  TBD.

## Crash UX (Scenario 3)

_See [SCENARIOS.md → Scenario 3](dracu_app/observability/SCENARIOS.md#scenario-3--deliberate-dart-crash)._

- **Time from crash → dashboard visibility:** Expected ~60 s
  after the **next** app launch (Embrace stages crash payloads
  on disk, uploads on next start).
- **Was the Dart stack trace symbolicated (real method names
  like `_throwDartException`) or mangled (`aQ5#1`)?** TBD —
  this is the symbolication-discipline checkpoint. If the
  Swazzler's `[Embrace] Uploaded mapping for ...` line was in
  the build log AND the build was `--obfuscate
  --split-debug-info=build/symbols`, frames should be readable.
  If they're mangled, run `make upload-android-mapping` and
  re-trigger the crash.
- **Pre-crash breadcrumb timeline length:** Expected ~4
  breadcrumbs ("nav: DracuNews", "nav: DracuChat", "nav: Debug",
  "debug: about to throw Dart exception") in the dashboard's
  Sessions view.
- **Was the user persona ("returning" / "power-user") tagged on
  the crashed session?** TBD — depends on whether the launch
  counter has reached the threshold by the time the Maestro
  flow runs.

## ANR UX (Scenario 4)

_See [SCENARIOS.md → Scenario 4](dracu_app/observability/SCENARIOS.md#scenario-4--anr-application-not-responding)._

- **Did the OS show the ANR dialog?** TBD. Android emulator
  WatchDog timing is sometimes erratic on slower hosts; if the
  dialog doesn't appear within 8 s, lengthen the busy-wait in
  `lib/debug/crash_button.dart` from 6 s to 10 s.
- **Did Embrace's session payload include
  `application_not_responding`?** TBD. Embrace's Android SDK
  samples the main thread every 100 ms during the freeze; the
  captured payload should show `_triggerAnr` at the top of the
  stack.
- **iOS App Hang equivalent:** **Not locally verifiable.**
  Requires the macOS CI runner. The
  `.github/workflows/embrace-ci.yml` `ios` job is wired to build
  the IPA with the same harness; running the equivalent
  Maestro flow on iOS Simulator from CI is a follow-up.

## Costs / ergonomics summary

| Question | Embrace answer |
|---|---|
| Setup time | ~2 hours (Embrace account + per-platform native bootstrap + Swazzler + Pod install on iOS) |
| Memory budget on dev box | 0 (SaaS) |
| Memory budget on user's device | ~3-5 MB per platform (claim from Embrace docs, not yet measured) |
| Per-event pricing? | No, per-MAU. Free tier covers 5K MAU. |
| Lock-in | Very high. No self-hosted, no data-export API. |
| Best feature found so far | Per-session breadcrumb timeline + crash UX (capture-on-restart upload). |
| Worst friction so far | Backend opacity (lesson, not a bug — but unsettling). |
| Where would I use this again? | Anywhere with a real mobile install base. |
| Where would I avoid this? | Backend services, web-only apps, projects with strict data-residency requirements. |

## Comparison with the other PoCs

Once Phase 6 of all five PoCs (Sentry-baseline, LGTM, Honeycomb,
Coroot, Elastic, Embrace) is complete, the natural follow-up is
a single comparison post showing all five `obs-experiment-notes.md`
files diff'd against each other on the "First impressions" and
"Costs / ergonomics summary" sections. That comparison artefact
lives at:
[`dev/observability_architectures_summary.md`](../dev/observability_architectures_summary.md).

The Embrace row in that doc's cross-architecture trade-offs
table is the one-line summary; this notes file is the
hands-on backup for it.

## Branches touched on this PoC

| Repo | Branch | Notable changes |
|---|---|---|
| `Draculin-Front` | `obs-experiment-embrace` | Embrace SDK + native bootstrap on Android & iOS; HTTP wrapper; debug crash harness; Maestro flows; Makefile + GitHub Actions. |
| `Draculin-Backend` | `obs-experiment-embrace` | Sentry **deleted**. Backend is opaque to Embrace by design. |
