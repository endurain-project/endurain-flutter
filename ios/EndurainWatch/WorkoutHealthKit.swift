import Foundation
import HealthKit

/// How the watch maps its activity types onto HealthKit workouts, and the
/// HealthKit access a workout needs.
enum WorkoutHealthKit {
    static func configuration(for type: WatchActivityType) -> HKWorkoutConfiguration {
        let configuration = HKWorkoutConfiguration()
        switch type {
        case .run:
            configuration.activityType = .running
        case .ride:
            configuration.activityType = .cycling
        case .walk:
            configuration.activityType = .walking
        case .hike:
            configuration.activityType = .hiking
        }
        configuration.locationType = .outdoor
        return configuration
    }

    static func activityType(for configuration: HKWorkoutConfiguration) -> WatchActivityType {
        switch configuration.activityType {
        case .cycling:
            return .ride
        case .walking:
            return .walk
        case .hiking:
            return .hike
        default:
            return .run
        }
    }

    /// Asks to save workouts, routes, distance and energy, and to read only
    /// what the workout screen shows: heart rate and distance. Energy is
    /// saved with the workout but never read, so it is not requested.
    static func requestAuthorization(_ healthStore: HKHealthStore) async throws {
        let share: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
        ]
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.distanceCycling),
        ]
        try await healthStore.requestAuthorization(toShare: share, read: read)
    }
}
