# ── Embrace Mobile RUM (obs-experiment-embrace branch) ───────────────
#
# The Embrace SDK uses reflection on its own internal classes (the
# entrypoint shim plus the OkHttp / WorkManager interceptors). R8 must
# leave them alone or release builds NoClassDefFoundError on first
# session capture.
#
# Reference: https://embrace.io/docs/android/integration/proguard/
-keep class io.embrace.android.embracesdk.** { *; }
-keep interface io.embrace.android.embracesdk.** { *; }
-dontwarn io.embrace.**

# ── Flutter ──────────────────────────────────────────────────────────
#
# Flutter's plugin registrar looks up entry-point classes by name at
# Dart isolate startup; R8 stripping their names breaks plugin wiring.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ── Camera plugin (from `package:camera`) ────────────────────────────
#
# CameraX uses reflection for codec selection. Without these, release
# builds crash with `NoSuchMethodException` the first time you open
# DracuVision on the obfuscated APK.
-keep class androidx.camera.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver
