import Foundation
import HealthKit

/// Method-channel error codes for a failed HealthKit read, matching the ones
/// the `health` plugin uses, so Dart can tell a locked device from a lasting
/// failure.
enum HealthKitErrorCode {
    static func code(for error: Error) -> String {
        guard let hkError = error as? HKError else {
            return "HEALTH_ERROR"
        }
        switch hkError.code {
        case .errorDatabaseInaccessible:
            return "DEVICE_LOCKED"
        case .errorAuthorizationDenied, .errorAuthorizationNotDetermined:
            return "PERMISSION_DENIED"
        case .errorHealthDataUnavailable, .errorHealthDataRestricted:
            return "NOT_SUPPORTED"
        default:
            return "HEALTH_ERROR"
        }
    }
}
