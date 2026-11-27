import HealthKit

/// How Endurain activity types map onto HealthKit workout activity types.
///
/// Compiled into both targets so the phone and the watch agree. Unknown types
/// have no mapping here: each caller applies its own fallback, because the
/// phone records any activity type (falling back to `.other`) while the watch
/// only records the four `WatchActivityType` cases (falling back to `.run`).
extension WatchActivityType {
    /// The HealthKit activity type a workout of this type is recorded as.
    var healthKitActivityType: HKWorkoutActivityType {
        switch self {
        case .run:
            return .running
        case .ride:
            return .cycling
        case .walk:
            return .walking
        case .hike:
            return .hiking
        }
    }

    /// The type a HealthKit activity type maps back to, or nil if none does.
    init?(healthKit activityType: HKWorkoutActivityType) {
        guard let match = Self.allCases.first(where: {
            $0.healthKitActivityType == activityType
        }) else {
            return nil
        }
        self = match
    }

    /// The HealthKit activity type of an Endurain activity type string
    /// (`ActivityType.apiValue`), or nil when it is not one of the four.
    static func healthKitActivityType(forApiValue value: String) -> HKWorkoutActivityType? {
        return WatchActivityType(rawValue: value)?.healthKitActivityType
    }
}
