import CoreLocation
import Foundation
import HealthKit
import os

/// The GPS track of the workout being recorded on the watch.
///
/// Filters Core Location fixes, stamps them with the latest heart rate, adds
/// them to the HealthKit workout route, and writes them in batches to the
/// durable [WatchRecordingStore], so a crash costs at most one batch.
@MainActor
final class WorkoutRouteRecorder {
    nonisolated private static let log = AppLogger.make(category: "WorkoutRouteRecorder")

    /// GPS fixes less accurate than this are not recorded.
    static let maxHorizontalAccuracyMeters: CLLocationAccuracy = 50

    /// A heart rate reading older than this is not attached to a point.
    static let heartRateFreshness: TimeInterval = 10

    /// Points are written to disk in batches of this size.
    static let pointFlushThreshold = 10

    private let healthStore: HKHealthStore
    private let store: WatchRecordingStore
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var routeHasData = false
    private var unsavedPoints: [WatchRecordedPoint] = []
    private var lastHeartRate: (bpm: Int, at: Date)?

    /// Every point of the workout so far, including those recorded before a
    /// relaunch.
    private(set) var points: [WatchRecordedPoint] = []

    init(healthStore: HKHealthStore, store: WatchRecordingStore) {
        self.healthStore = healthStore
        self.store = store
    }

    /// Starts the track of a new or recovered workout. A recovered workout
    /// starts a new route builder: the track recorded before the relaunch is
    /// re-inserted so the saved route is complete.
    func begin(with points: [WatchRecordedPoint]) {
        self.points = points
        unsavedPoints = []
        lastHeartRate = nil
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        routeHasData = false
        insertIntoRoute(points.map(Self.location(from:)))
    }

    func reset() {
        routeBuilder = nil
        routeHasData = false
        points = []
        unsavedPoints = []
        lastHeartRate = nil
    }

    func noteHeartRate(_ bpm: Int, at date: Date) {
        lastHeartRate = (bpm, date)
    }

    /// Adds the usable fixes of a running [recording] to the track.
    func record(_ locations: [CLLocation], for recording: WatchRecording) {
        let accepted = locations.filter { location in
            location.horizontalAccuracy >= 0
                && location.horizontalAccuracy <= Self.maxHorizontalAccuracyMeters
                && location.timestamp >= recording.startedAt
        }
        guard !accepted.isEmpty else { return }
        let newPoints = accepted.map { location in
            Self.point(
                from: location,
                segmentIndex: recording.segmentIndex,
                heartRateBpm: freshHeartRate(at: location.timestamp)
            )
        }
        points.append(contentsOf: newPoints)
        unsavedPoints.append(contentsOf: newPoints)
        insertIntoRoute(accepted)
        if unsavedPoints.count >= Self.pointFlushThreshold {
            flush()
        }
    }

    /// Writes the points not yet on disk.
    func flush() {
        guard !unsavedPoints.isEmpty else { return }
        do {
            try store.append(unsavedPoints)
            unsavedPoints = []
        } catch {
            // Kept in memory and retried with the next batch.
            Self.log.error("Could not save workout points: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// Saves the route to [workout], when the track has any point.
    func finishRoute(with workout: HKWorkout) async {
        guard routeHasData, let routeBuilder else { return }
        _ = try? await routeBuilder.finishRoute(with: workout, metadata: nil)
    }

    // MARK: - Private

    private func freshHeartRate(at date: Date) -> Int? {
        guard let lastHeartRate,
              abs(date.timeIntervalSince(lastHeartRate.at)) <= Self.heartRateFreshness
        else {
            return nil
        }
        return lastHeartRate.bpm
    }

    private func insertIntoRoute(_ locations: [CLLocation]) {
        guard !locations.isEmpty, let routeBuilder else { return }
        routeHasData = true
        routeBuilder.insertRouteData(locations) { _, error in
            if let error {
                Self.log.error("Could not add to the workout route: \(error.localizedDescription, privacy: .private)")
            }
        }
    }

    // MARK: - Conversion

    nonisolated static func point(
        from location: CLLocation,
        segmentIndex: Int,
        heartRateBpm: Int?
    ) -> WatchRecordedPoint {
        let hasAltitude = location.verticalAccuracy >= 0
        return WatchRecordedPoint(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            segmentIndex: segmentIndex,
            elevationMeters: hasAltitude ? location.altitude : nil,
            horizontalAccuracyMeters: location.horizontalAccuracy,
            verticalAccuracyMeters: hasAltitude ? location.verticalAccuracy : nil,
            headingDegrees: location.course >= 0 ? location.course : nil,
            speedMetersPerSecond: location.speed >= 0 ? location.speed : nil,
            speedAccuracyMetersPerSecond: location.speedAccuracy >= 0 ? location.speedAccuracy : nil,
            heartRateBpm: heartRateBpm
        )
    }

    nonisolated static func location(from point: WatchRecordedPoint) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: point.latitude,
                longitude: point.longitude
            ),
            altitude: point.elevationMeters ?? 0,
            horizontalAccuracy: point.horizontalAccuracyMeters ?? 10,
            verticalAccuracy: point.elevationMeters == nil ? -1 : (point.verticalAccuracyMeters ?? 10),
            course: point.headingDegrees ?? -1,
            speed: point.speedMetersPerSecond ?? -1,
            timestamp: point.timestamp
        )
    }
}
