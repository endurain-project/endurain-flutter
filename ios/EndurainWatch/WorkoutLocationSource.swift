import CoreLocation
import Foundation
import os

/// The Core Location stream of a watch workout.
///
/// Runs best-accuracy fitness updates, background included, from the start
/// countdown (to warm up GPS) to the end of the workout, and reports fixes
/// and authorization changes to its owner on the main actor.
@MainActor
final class WorkoutLocationSource: NSObject {
    nonisolated private static let log = AppLogger.make(category: "WorkoutLocationSource")

    private let manager = CLLocationManager()
    private var isUpdating = false
    private var didRequestFullAccuracy = false

    /// Key of the purpose string under
    /// `NSLocationTemporaryUsageDescriptionDictionary` in Info.plist.
    static let fullAccuracyPurposeKey = "EndurainWorkoutRoute"

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
        } else {
            requestFullAccuracyIfNeeded()
        }
    }

    /// A route recorded with approximate location is useless, so when the
    /// user granted access but turned Precise Location off, asks once per
    /// launch to turn it on for now. The workout records either way.
    func requestFullAccuracyIfNeeded() {
        guard !didRequestFullAccuracy else { return }
        didRequestFullAccuracy = manager.requestPreciseLocationIfNeeded(
            purposeKey: Self.fullAccuracyPurposeKey
        )
    }

    func start() {
        guard !isUpdating else { return }
        isUpdating = true
        manager.applyFitnessConfiguration(distanceFilter: kCLDistanceFilterNone)
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func stop() {
        guard isUpdating else { return }
        isUpdating = false
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
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
        Self.log.error("Location update failed: \(error.localizedDescription, privacy: .private)")
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.onAuthorizationChange?(status)
            self.requestFullAccuracyIfNeeded()
        }
    }
}
