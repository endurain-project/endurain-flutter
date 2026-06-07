import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Strong reference so the native activity recorder channel outlives engine
  /// setup and keeps its method/event handlers registered.
  private var activityRecorderChannel: ActivityRecorderChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EndurainActivityRecorderChannel"
    ) {
      let channel = ActivityRecorderChannel()
      channel.register(with: registrar.messenger())
      activityRecorderChannel = channel
    }
  }
}
