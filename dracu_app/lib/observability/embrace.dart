/// Thin facade over the `package:embrace` API surface used by the
/// Draculin Flutter app on the `obs-experiment-embrace` branch.
///
/// Why a facade and not direct calls into `package:embrace`?
///
/// * **Single chokepoint for vendor swap.** If we ever switch from
///   Embrace to (say) Datadog Mobile RUM or Sentry Flutter, only
///   this file changes — every screen / handler / network call
///   imports `package:dracu_app/observability/embrace.dart`, never
///   `package:embrace/embrace.dart` directly.
/// * **Type-narrowing for the call sites.** Embrace exposes
///   ~30 methods on the singleton; we re-export the ~6 we
///   actually use (breadcrumb, info/warn/error, recordSpan,
///   addPersona, currentSessionId) with defensive try/catch on
///   each call.
/// * **Test seam.** Unit tests can `import` this module and stub
///   the methods without dragging the platform-channel-dependent
///   real SDK into the test harness.
///
/// Network-event recording is intentionally NOT exposed here —
/// the SDK's own `EmbraceHttpClient` handles it auto-magically
/// when used as the `_inner` of `DracuHttpClient`. Adding a
/// duplicate manual recording API would be a footgun.
///
/// Discipline: every method here MUST be a no-op when the SDK
/// hasn't started or the platform doesn't support it (Flutter Web,
/// uninitialised desktop builds). The Embrace SDK itself handles
/// most of those cases — this facade adds a defensive try/catch
/// around every call so an SDK-internal bug can never propagate to
/// the app.
library;

import 'package:embrace/embrace.dart';
// `embrace_api` is a separate library file *within* the `embrace`
// package (not a separate pub dependency). It carries the value
// types (`EmbraceSpan`, `ErrorCode`, ...) while the top-level
// library carries the singleton class.
import 'package:embrace/embrace_api.dart' show EmbraceSpan, ErrorCode;

// Re-export EmbraceSpan + ErrorCode so call sites in `lib/main.dart`
// can hold onto a span handle for nesting children + signal failure
// without needing to import `package:embrace/embrace_api.dart`
// directly.
export 'package:embrace/embrace_api.dart' show EmbraceSpan, ErrorCode;

class DracuObs {
  DracuObs._();

  /// Get the current Embrace session ID for cross-tier correlation
  /// header injection. Returns null if the SDK isn't started or the
  /// platform doesn't expose a session ID. Async because the iOS
  /// native bridge round-trips for it.
  static Future<String?> currentSessionId() async {
    try {
      return await Embrace.instance.getCurrentSessionId();
    } catch (_) {
      return null;
    }
  }

  /// Add a free-form breadcrumb to the active session. Maps to
  /// Embrace's flagship "what-happened-before-the-crash" UX. Keep
  /// messages low-cardinality (no user input, no IDs) so the
  /// timeline stays readable.
  static void breadcrumb(String message) {
    try {
      Embrace.instance.addBreadcrumb(message);
    } catch (_) {}
  }

  /// Log a message at INFO. `properties` are searchable in the
  /// dashboard; keep them small and string-typed (Embrace's API
  /// requires `Map<String, String>`).
  static void info(String message, {Map<String, String>? properties}) {
    try {
      Embrace.instance.logInfo(message, properties: properties);
    } catch (_) {}
  }

  /// Log a message at WARNING. Use for recoverable anomalies
  /// (retried HTTP request, fallback model loaded, etc.).
  static void warn(String message, {Map<String, String>? properties}) {
    try {
      Embrace.instance.logWarning(message, properties: properties);
    } catch (_) {}
  }

  /// Log a message at ERROR. Errors surface in the dashboard's
  /// "Logs" tab and contribute to the error-free-session metric.
  /// Prefer `logHandledError` when there's a real exception object
  /// — it gives Embrace a stack trace to symbolicate.
  static void error(String message, {Map<String, String>? properties}) {
    try {
      Embrace.instance.logError(message, properties: properties);
    } catch (_) {}
  }

  /// Record a handled (caught) exception with its stack trace.
  /// Does NOT count against crash-free-session — that's why it's
  /// "handled". For unhandled exceptions, the runZonedGuarded
  /// wrapper installed in `main.dart` catches them automatically.
  static void recordHandledError(Object err, StackTrace stack) {
    try {
      Embrace.instance.logHandledDartError(err, stack);
    } catch (_) {}
  }

  /// Wrap a Future-returning closure in an Embrace span. Used in
  /// Phase 4 around the camera-capture multipart upload. The span
  /// shows up in the dashboard's "Performance" tab. `attributes`
  /// must be string-string per Embrace's wire format. Pass
  /// `parent` to nest the span under an outer one started with
  /// [startSpan] — the dashboard will render the parent/child tree.
  ///
  /// `code` is named (matching Embrace's own SDK convention) so
  /// call sites read top-to-bottom: name, parent/attributes, then
  /// the closure on its own line.
  static Future<T> recordSpan<T>(
    String name, {
    required Future<T> Function() code,
    EmbraceSpan? parent,
    Map<String, String>? attributes,
  }) async {
    try {
      return await Embrace.instance.recordSpan<T>(
        name,
        parent: parent,
        attributes: attributes,
        code: code,
      );
    } catch (_) {
      // If the SDK call throws, run the body bare so observability
      // failures never affect app behaviour.
      return code();
    }
  }

  /// Manually start a span. Returns a handle; the caller is
  /// responsible for calling `.stop()` on it (with an optional
  /// `ErrorCode` if the operation failed). Use this when you need
  /// children to live under a single parent that spans multiple
  /// phases — `recordSpan` is sufficient when the parent's body
  /// fits in one closure. `null` is returned when the SDK isn't
  /// running.
  static Future<EmbraceSpan?> startSpan(String name,
      {EmbraceSpan? parent}) async {
    try {
      return await Embrace.instance.startSpan(name, parent: parent);
    } catch (_) {
      return null;
    }
  }

  /// Add a user persona tag for session segmentation. Embrace's
  /// "Personas" feature filters dashboards by these labels — used
  /// in Phase 4 to mark first-time vs. returning vs. power users.
  /// Persona names are limited to 32 chars and lowercase by
  /// convention.
  static void addPersona(String persona) {
    try {
      Embrace.instance.addUserPersona(persona);
    } catch (_) {}
  }
}
