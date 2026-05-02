/// DEBUG-only screen exposing three buttons that intentionally
/// fail the app in different ways, so the Maestro flows in
/// `observability/load-test/` can drive Embrace's crash / ANR /
/// Dart-exception capture pipeline end-to-end.
///
/// Wired into the BottomNavigationBar as a hidden 6th tab that
/// only renders when the build is `kDebugMode`. Release builds
/// drop this tab entirely (and the FloatingActionButton handlers
/// inside it) — the file still ships in the APK because Dart tree
/// shaking can't statically prove kDebugMode is false at compile
/// time, but the user-facing entry points are gone.
///
/// References:
///   * Throw Dart Exception → tests Embrace.installErrorHandlers'
///     runZonedGuarded path. Stack trace lands in dashboard's
///     "Sessions" panel under the affected session.
///   * Native Crash → invokes a MethodChannel call with no
///     registered handler, raising a MissingPluginException on
///     the Dart side. For a TRUE native NDK crash, see the
///     comment on _triggerNativeCrash below.
///   * ANR → blocks the platform thread for >5 s. On Android,
///     the OS shows the "App Not Responding" dialog and Embrace
///     captures the stack at the moment the OS detected the
///     freeze. iOS equivalent is "App Hang" (only fires on
///     macOS-built artefacts).
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../observability/embrace.dart';

/// Use as a screen in the BottomNavigationBar's `_pages` list,
/// gated by `if (kDebugMode) ... CrashButtonScreen()`.
class CrashButtonScreen extends StatelessWidget {
  const CrashButtonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Center(
        child: Text(
          'Debug-only screen.\nNot accessible in release builds.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'DEBUG: Embrace verification harness',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Each button intentionally fails the app in a way Embrace\nshould capture. After tapping, kill+restart the app and\ncheck the dashboard within ~60 s.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FloatingActionButton.extended(
                heroTag: 'embrace-crash-dart',
                backgroundColor: Colors.orange,
                onPressed: _throwDartException,
                icon: const Icon(Icons.bug_report),
                label: const Text('Throw Dart Exception'),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                heroTag: 'embrace-crash-native',
                backgroundColor: Colors.deepOrange,
                onPressed: _triggerNativeCrash,
                icon: const Icon(Icons.warning),
                label: const Text('Native Crash'),
              ),
              const SizedBox(height: 16),
              FloatingActionButton.extended(
                heroTag: 'embrace-crash-anr',
                backgroundColor: Colors.red,
                onPressed: _triggerAnr,
                icon: const Icon(Icons.timer_off),
                label: const Text('ANR (6s main-thread sleep)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Throw a synchronous Dart exception. Caught by the
  /// runZonedGuarded that `Embrace.installErrorHandlers` installed
  /// in main.dart, then forwarded to the SDK as an unhandled
  /// Dart error. Counts AGAINST the crash-free-session metric.
  ///
  /// Drops a breadcrumb first so the dashboard shows the trail
  /// leading up to the crash (otherwise it just shows the
  /// FloatingActionButton tap event from the framework).
  void _throwDartException() {
    DracuObs.breadcrumb('debug: about to throw Dart exception');
    throw StateError('Intentional crash from Embrace verification harness');
  }

  /// Invoke a MethodChannel call with no registered native
  /// handler. Raises `MissingPluginException`, which our Dart
  /// catch in `installErrorHandlers` will receive as an
  /// unhandled error.
  ///
  /// For a TRUE NDK crash (segfault / SIGABRT) you'd need a
  /// native side that intentionally calls `__builtin_trap()` or
  /// `abort()`. We don't ship that because (a) it requires
  /// adding a Kotlin/Swift method just for crash testing and
  /// (b) the MethodChannel-not-found path is sufficient to
  /// exercise Embrace's "uncaught from a platform call" pipeline.
  /// Mark TODO if a future iteration wants the segfault variant.
  Future<void> _triggerNativeCrash() async {
    DracuObs.breadcrumb('debug: invoking unregistered MethodChannel');
    const platform = MethodChannel('embrace.debug/crash');
    await platform.invokeMethod('crash');
  }

  /// Block the main isolate for 6 seconds. Android's WatchDog
  /// thread fires the "App Not Responding" dialog at 5 s. The
  /// Embrace Android SDK's ANR detector samples the main thread's
  /// stack trace every 100 ms during the freeze, so the captured
  /// payload includes a full call-stack snapshot at the moment
  /// the OS gave up.
  ///
  /// Implemented with a busy-wait rather than `sleep()` so the
  /// thread is actually pegged — a `sleep` would yield to the OS
  /// scheduler and might not trigger ANR detection on faster
  /// devices.
  void _triggerAnr() {
    DracuObs.breadcrumb('debug: pegging main thread for 6s (ANR)');
    final until = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(until)) {
      // Busy-wait — intentional.
    }
  }
}

/// Helper for the call site in main.dart that conditionally adds
/// the 6th nav tab. Wrapping the kDebugMode check here keeps the
/// build() method clean.
List<Widget> debugCrashTabPages() {
  return kDebugMode ? const [CrashButtonScreen()] : const [];
}

/// Same as above for the BottomNavigationBarItem entry.
List<BottomNavigationBarItem> debugCrashTabItems() {
  return kDebugMode
      ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: 'Debug',
          ),
        ]
      : const [];
}
