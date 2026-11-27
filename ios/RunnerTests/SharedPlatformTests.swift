import CoreLocation
import HealthKit
import XCTest

@testable import Runner

/// The helpers in `ios/Shared/Platform`, compiled into both the phone and the
/// watch app. The watch has its own tests of the HealthKit mapping.
@MainActor
final class SharedPlatformTests: XCTestCase {
    func testPhoneFallsBackToOtherForUnknownActivityTypes() {
        XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: "swim"), .other)
        XCTAssertEqual(HealthKitHeartRateMonitor.workoutActivityType(for: ""), .other)
    }

    func testPhoneAndWatchShareOneMapping() {
        for type in WatchActivityType.allCases {
            XCTAssertEqual(
                HealthKitHeartRateMonitor.workoutActivityType(for: type.rawValue),
                type.healthKitActivityType
            )
        }
    }

    func testFitnessConfigurationKeepsEachCallersDistanceFilter() {
        let manager = CLLocationManager()
        manager.applyFitnessConfiguration(distanceFilter: 3)
        XCTAssertEqual(manager.activityType, .fitness)
        XCTAssertEqual(manager.desiredAccuracy, kCLLocationAccuracyBest)
        XCTAssertEqual(manager.distanceFilter, 3)

        manager.applyFitnessConfiguration(distanceFilter: kCLDistanceFilterNone)
        XCTAssertEqual(manager.distanceFilter, kCLDistanceFilterNone)
    }

    func testNoPreciseLocationRequestWithoutAuthorization() throws {
        let manager = CLLocationManager()
        try XCTSkipIf(
            manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .authorizedAlways,
            "Needs a simulator that has not granted location access."
        )
        XCTAssertFalse(manager.requestPreciseLocationIfNeeded(purposeKey: "Unused"))
    }

    func testEveryPurposeKeyIsDeclaredInThePhoneInfoPlist() throws {
        let dictionary = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary")
                as? [String: String]
        )
        XCTAssertNotNil(dictionary[CoreLocationActivityRecorder.fullAccuracyPurposeKey])
    }
}
