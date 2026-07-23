import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var mapsApiKeyConfigured = false
  private var mapsChannelRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required before any GoogleMap Flutter view is created.
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !apiKey.isEmpty,
       !apiKey.hasPrefix("$(") {
      GMSServices.provideAPIKey(apiKey)
      mapsApiKeyConfigured = true
    } else {
      mapsApiKeyConfigured = false
      NSLog("⚠️ GMSApiKey missing — set GOOGLE_MAPS_API_KEY in ios/Flutter/Secrets.xcconfig")
    }
    UserDefaults.standard.set(mapsApiKeyConfigured, forKey: "afropeep.mapsApiKeyConfigured")

    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // window/root VC often nil until after super — register channel on next runloop.
    DispatchQueue.main.async { [weak self] in
      self?.registerMapsConfigChannel()
    }
    return launched
  }

  private func registerMapsConfigChannel() {
    guard !mapsChannelRegistered else { return }
    guard let controller = window?.rootViewController as? FlutterViewController else {
      // Retry once shortly after first frame.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        self?.registerMapsConfigChannel()
      }
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.app.naijasingles/maps_config",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "gone", message: nil, details: nil))
        return
      }
      if call.method == "isMapsApiKeyConfigured" {
        result(self.mapsApiKeyConfigured)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    mapsChannelRegistered = true
  }
}
