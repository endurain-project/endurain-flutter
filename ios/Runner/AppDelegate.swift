import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Strong reference so the native activity recorder channel outlives engine
  /// setup and keeps its method/event handlers registered.
  private var activityRecorderChannel: ActivityRecorderChannel?

  /// Strong reference for device-region settings queried by Flutter.
  private var deviceSettingsChannel: FlutterMethodChannel?

  /// Strong reference so the companion watch transport keeps its handlers.
  private var watchTransportChannel: WatchTransportChannel?

  /// Strong reference so Health Sync's heart rate series reader stays registered.
  private var heartRateSeriesChannel: HeartRateSeriesChannel?

  /// The single activity recorder, created at launch so its location
  /// manager and delegate exist before iOS delivers the event a background
  /// relaunch was for, and handed to the recorder channel once the Flutter
  /// engine (which may start late, or not at all, in the background) is up.
  private var activityRecorder: CoreLocationActivityRecorder?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeHealthDataFromBackup()
    // A recording interrupted by termination continues as soon as the
    // process is back, whatever relaunched it: significant-location-change
    // monitoring, which the recorder arms while a recording is active, or
    // the user. The `.location` launch option is not used because it is
    // unreliable for scene-based apps. Resuming here rather than when Dart
    // attaches matters: a background relaunch has a short execution window,
    // and the durable store already holds everything needed to continue.
    let recorder = CoreLocationActivityRecorder(store: .shared)
    activityRecorder = recorder
    recorder.resumeAfterRelaunch()
    // Activated before the engine so sessions the watch queued while the app
    // was closed land in the durable inbox as soon as they are delivered.
    WatchConnectivityBridge.shared.activate()
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
      forPlugin: "EndurainDeviceSettingsChannel"
    ) {
      let channel = FlutterMethodChannel(
        name: "endurain/device_settings",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "getMeasurementSystem" else {
          result(FlutterMethodNotImplemented)
          return
        }
        if #available(iOS 16.0, *) {
          result(Locale.current.measurementSystem == .metric ? "metric" : "imperial")
        } else {
          result(Locale.current.usesMetricSystem ? "metric" : "imperial")
        }
      }
      deviceSettingsChannel = channel
    }
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EndurainWatchTransportChannel"
    ) {
      let channel = WatchTransportChannel()
      channel.register(with: registrar.messenger())
      watchTransportChannel = channel
    }
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EndurainHeartRateSeriesChannel"
    ) {
      let channel = HeartRateSeriesChannel()
      channel.register(with: registrar.messenger())
      heartRateSeriesChannel = channel
    }
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EndurainActivityRecorderChannel"
    ) {
      let channel = ActivityRecorderChannel(store: .shared, recorder: activityRecorder)
      channel.register(with: registrar.messenger())
      activityRecorderChannel = channel
    }
  }
}
