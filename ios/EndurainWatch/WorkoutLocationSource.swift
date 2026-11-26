import CoreLocation
import Foundation

/// The Core Location stream of a watch workout.
///
/// Runs best-accuracy fitness updates, background included, from the start
/// countdown (to warm up GPS) to the end of the workout, and reports fixes
/// and authorization changes to its owner on the main actor.
@MainActor
final class WorkoutLocationSource: NSObject {
    private let manager = CLLocationManager()
    private var isUpdating = false

    /// Called with every batch of fixes Core Location delivers.
    var onLocations: (([CLLocation]) -> Void)?

    /// Called when the location authorization changes.
    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    var authorizationStatus: CLAuthorizationStatus {
        return manager.authorizationStatus
    }

    /// Asks for When In Use access if the user has not answered yet.
    func requestAuthorizationIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func start() {
        guard !isUpdating else { return }
        isUpdating = true
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func stop() {
        guard isUpdating else { return }
        isUpdating = false
        manager.stopUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension WorkoutLocationSource: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            self.onLocations?(locations)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Endurain watch: location update failed: %@", error.localizedDescription)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.onAuthorizationChange?(status)
        }
    }
}
