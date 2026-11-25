import CoreLocation
import Foundation

/// Keeps the app running while the start countdown runs with the screen
/// locked.
///
/// iOS suspends an app soon after the screen locks unless it is doing
/// something allowed in the background, and nothing records during the
/// countdown. Running location updates is allowed, so this starts them with
/// its own manager and drops every fix: the app stays awake for the whole
/// countdown, and GPS has a fix by the time the recorder starts. It never
/// touches the durable session store.
@MainActor
final class StartCountdownWarmUp: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var isRunning = false

    override init() {
        super.init()
        manager.delegate = self
    }

    /// Starts the warm-up. Does nothing when location is not authorized: the
    /// recording asks for permission itself, and the countdown then just runs
    /// in the foreground.
    func begin() {
        guard !isRunning else { return }
        let status = manager.authorizationStatus
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            return
        }
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
        isRunning = true
    }

    /// Stops the warm-up. Safe to call when it is not running.
    func end() {
        guard isRunning else { return }
        isRunning = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        // Dropped on purpose: nothing is recorded before the countdown ends.
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
