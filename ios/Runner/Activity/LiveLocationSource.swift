import CoreLocation
import Foundation

/// One update from a `LiveLocationSource`.
struct LiveLocationUpdate {
    /// The fix, when the update carries one.
    let location: CLLocation?

    /// Whether the device is not moving. Core Location then stops delivering
    /// updates until it moves again, so no further fix follows this one while
    /// the device stays still.
    let isStationary: Bool
}

/// Delivers fitness location updates that keep arriving while the app is in
/// the background.
///
/// A protocol so the recorder can be driven by a fake stream in tests;
/// `CoreLocationLiveUpdates` is the only production implementation.
@MainActor
protocol LiveLocationSource: AnyObject {
    /// Whether updates are being delivered.
    var isRunning: Bool { get }

    /// Starts delivering updates to [onUpdate] on the main actor. Does
    /// nothing while already running, so a running stream keeps its handler.
    func start(onUpdate: @escaping @MainActor (LiveLocationUpdate) -> Void)

    /// Stops the updates. Safe to call when not running.
    func stop()
}

/// `LiveLocationSource` backed by `CLLocationUpdate.liveUpdates(.fitness)`.
///
/// Holds a `CLBackgroundActivitySession` while running, which keeps updates
/// coming after the app is backgrounded and shows the system location
/// indicator. If iOS terminates the app while that session is active, it
/// relaunches the app in the background when updates resume; `AppDelegate`
/// then restarts the recording on launch (see
/// `CoreLocationActivityRecorder.resumeAfterRelaunch`). On iOS 18 and later a
/// `CLServiceSession` also declares that the recording needs When In Use
/// access with precise location, so iOS asks to turn Precise Location on for
/// the recording when it is off.
@MainActor
final class CoreLocationLiveUpdates: LiveLocationSource {
    private var updatesTask: Task<Void, Never>?
    private var backgroundSession: CLBackgroundActivitySession?
    /// The iOS 18 `CLServiceSession`, held untyped because a stored property
    /// cannot be limited to an OS version.
    private var serviceSession: AnyObject?

    var isRunning: Bool {
        return updatesTask != nil
    }

    func start(onUpdate: @escaping @MainActor (LiveLocationUpdate) -> Void) {
        guard updatesTask == nil else {
            return
        }
        backgroundSession = CLBackgroundActivitySession()
        if #available(iOS 18.0, *) {
            serviceSession = CLServiceSession(
                authorization: .whenInUse,
                fullAccuracyPurposeKey: CoreLocationActivityRecorder.fullAccuracyPurposeKey
            )
        }
        updatesTask = Task { @MainActor in
            do {
                for try await update in CLLocationUpdate.liveUpdates(.fitness) {
                    guard !Task.isCancelled else {
                        return
                    }
                    onUpdate(LiveLocationUpdate(
                        location: update.location,
                        isStationary: Self.isStationary(update)
                    ))
                }
            } catch {
                // The stream ends only when cancelled; a loss of access is
                // reported through the location manager's authorization
                // callback, which stops the recording.
            }
        }
    }

    /// iOS 18 renamed `isStationary` to `stationary`.
    private static func isStationary(_ update: CLLocationUpdate) -> Bool {
        if #available(iOS 18.0, *) {
            return update.stationary
        }
        return update.isStationary
    }

    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        backgroundSession?.invalidate()
        backgroundSession = nil
        if #available(iOS 18.0, *) {
            (serviceSession as? CLServiceSession)?.invalidate()
        }
        serviceSession = nil
    }
}
