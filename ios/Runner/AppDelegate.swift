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
    excludeHealthDataFromBackup()
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
    }
  }
}
