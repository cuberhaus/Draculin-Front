package com.example.dracu_app

import android.app.Application
import io.embrace.android.embracesdk.Embrace

/**
 * Application subclass added on the `obs-experiment-embrace` branch
 * so the Embrace Android SDK can be initialised in `onCreate`, BEFORE
 * the Flutter engine spins up its plugin registrant. This is the
 * earliest hook the OS gives us — anything later (e.g. inside
 * `MainActivity.onCreate`) would miss native crashes during the
 * Flutter cold-start window, which is precisely the slice Embrace's
 * "App Startup" panel exists to surface.
 *
 * The Dart-side `Embrace.instance.start(() => runApp(...))` call in
 * `lib/main.dart` is still required: it wraps the runZonedGuarded so
 * Dart-side uncaught exceptions become Embrace events. The two calls
 * coexist — the Kotlin call boots the native SDK, the Dart call
 * binds the Dart isolate's error zone to it.
 */
class DracuApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Reads `app_id` and `api_token` from
        // `android/app/src/main/embrace-config.json` (gitignored,
        // see embrace-config.json.example). Fails loudly with a
        // `RuntimeException` if the file is missing or malformed —
        // that's the desired behaviour: a misconfigured release
        // build should abort at first launch, not silently lose
        // every user's session.
        Embrace.getInstance().start(this)
    }
}
