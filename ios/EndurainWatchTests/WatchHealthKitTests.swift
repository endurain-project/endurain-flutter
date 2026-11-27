import HealthKit
import XCTest

@testable import EndurainWatch

final class WatchHealthKitTests: XCTestCase {
    func testEveryWatchActivityTypeMapsToItsHealthKitType() {
        XCTAssertEqual(WatchActivityType.run.healthKitActivityType, .running)
        XCTAssertEqual(WatchActivityType.ride.healthKitActivityType, .cycling)
        XCTAssertEqual(WatchActivityType.walk.healthKitActivityType, .walking)
        XCTAssertEqual(WatchActivityType.hike.healthKitActivityType, .hiking)
    }

    func testTheMappingRoundTrips() {
        for type in WatchActivityType.allCases {
            XCTAssertEqual(WatchActivityType(healthKit: type.healthKitActivityType), type)
        }
    }

    func testAnUnmappedHealthKitTypeHasNoWatchType() {
        XCTAssertNil(WatchActivityType(healthKit: .swimming))
        XCTAssertNil(WatchActivityType(healthKit: .other))
    }

    func testApiValuesMapAndUnknownOnesDoNot() {
        XCTAssertEqual(WatchActivityType.healthKitActivityType(forApiValue: "ride"), .cycling)
        XCTAssertNil(WatchActivityType.healthKitActivityType(forApiValue: "swim"))
        XCTAssertNil(WatchActivityType.healthKitActivityType(forApiValue: ""))
    }

    func testTheWorkoutConfigurationIsOutdoorOfTheRightType() {
        for type in WatchActivityType.allCases {
            let configuration = WorkoutHealthKit.configuration(for: type)
            XCTAssertEqual(configuration.activityType, type.healthKitActivityType)
            XCTAssertEqual(configuration.locationType, .outdoor)
        }
    }

    func testARecoveredWorkoutOfAnotherTypeIsRecordedAsARun() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .swimming
        XCTAssertEqual(WorkoutHealthKit.activityType(for: configuration), .run)
    }

    func testARecoveredWorkoutKeepsItsType() {
        for type in WatchActivityType.allCases {
            let configuration = WorkoutHealthKit.configuration(for: type)
            XCTAssertEqual(WorkoutHealthKit.activityType(for: configuration), type)
        }
    }
}
