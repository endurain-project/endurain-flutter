import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Strong reference so the native activity recorder channel outlives engine
  /// setup and keeps its method/event handlers registered.
  private var activityRecorderChannel: ActivityRecorderChannel?

  /// Whether iOS relaunched the process to deliver a location event.
  ///
  /// Set before the Flutter engine finishes initializing, and consumed in
  /// `didInitializeImplicitFlutterEngine` once the recorder channel exists.
  private var launchedForLocationEvent = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeHealthDataFromBackup()
    // A location key means the app was relaunched in the background by
    // significant-location-change monitoring, which the recorder arms while a
    // recording is active. Without this the process would start, do nothing,
    // and the remainder of the activity would be lost.
    launchedForLocationEvent = launchOptions?[.location] != nil
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func excludeHealthDataFromBackup() {
    guard let support = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    ).first else {
      return
    }
    let directoryNames = ["activity_records", "endurain_private"]
    for directoryName in directoryNames {
      var directory = support.appendingPathComponent(directoryName, isDirectory: true)
      do {
        try FileManager.default.createDirectory(
          at: directory,
          withIntermediateDirectories: true
        )
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try directory.setResourceValues(values)
      } catch {
        NSLog("Unable to exclude private Endurain storage from backup: %@", error.localizedDescription)
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EndurainActivityRecorderChannel"
    ) {
      let channel = ActivityRecorderChannel()
      channel.register(with: registrar.messenger())
      activityRecorderChannel = channel
      if launchedForLocationEvent {
        launchedForLocationEvent = false
        // Resume the accurate stream immediately rather than waiting for Dart
        // to attach: a background relaunch has a short execution window, and
        // the durable store already holds everything needed to continue.
        channel.resumeAfterRelaunch()
      }
    }
  }
}
