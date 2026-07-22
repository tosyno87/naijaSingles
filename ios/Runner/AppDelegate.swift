import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required before any GoogleMap Flutter view is created.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
    } else {
      NSLog("⚠️ GMSApiKey missing — set GOOGLE_MAPS_API_KEY in ios/Flutter/Secrets.xcconfig")
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
