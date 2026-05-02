import UIKit
import Flutter

// ── obs-experiment-embrace ────────────────────────────────────────────
// The Embrace iOS SDK requires native bootstrap BEFORE Flutter's
// plugin registrant runs (same reasoning as the Android
// DracuApplication subclass — cold-start native crashes would
// otherwise be invisible). We do this in AppDelegate.init, the
// earliest hook iOS gives an app delegate. The Dart-side
// `Embrace.instance.start(() => runApp(...))` call in lib/main.dart
// still runs and binds the Dart zone — the two calls coexist.
//
// The `appId` value is read from Embrace-Info.plist (gitignored;
// see Embrace-Info.plist.example). Hard-coding here would make the
// release build a binary-public credential leak.
import EmbraceIO
import EmbraceCore
import EmbraceCrash

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override init() {
    super.init()
    do {
      // Read appId from the bundle's Embrace-Info.plist so the same
      // binary can be built against multiple Embrace projects via
      // CI-time plist swaps.
      guard
        let plistPath = Bundle.main.path(forResource: "Embrace-Info", ofType: "plist"),
        let plistDict = NSDictionary(contentsOfFile: plistPath),
        let appId = plistDict["EMBRACE_APP_ID"] as? String,
        !appId.isEmpty,
        appId != "REPLACE_ME_12_CHAR_HEX"
      else {
        NSLog("[Embrace] Embrace-Info.plist missing or APP_ID unset; skipping native init. Mobile RUM will not capture iOS sessions.")
        return
      }
      try Embrace
        .setup(
          options: Embrace.Options(
            appId: appId,
            platform: .flutter
          )
        )
        .start()
    } catch let e {
      // Fail loud, don't crash. Embrace setup errors should be visible
      // in CI logs but must not prevent the app from launching for
      // users (e.g. misconfigured staging build).
      NSLog("[Embrace] setup failed: \(e.localizedDescription)")
    }
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
