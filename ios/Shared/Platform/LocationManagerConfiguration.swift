import CoreLocation

/// Core Location setup shared by every fitness location stream of the phone
/// and watch apps.
extension CLLocationManager {
    /// Configures the manager for a workout: fitness activity type, best
    /// accuracy and [distanceFilter] meters between updates
    /// (`kCLDistanceFilterNone` delivers every fix).
    func applyFitnessConfiguration(distanceFilter: CLLocationDistance) {
        activityType = .fitness
        desiredAccuracy = kCLLocationAccuracyBest
        self.distanceFilter = distanceFilter
    }

    /// A route recorded with approximate location is useless. When access is
    /// granted but Precise Location is off, asks to turn it on for now using
    /// the purpose string under [purposeKey] in
    /// `NSLocationTemporaryUsageDescriptionDictionary` of the target's
    /// Info.plist. Returns whether it asked, so callers can ask once per
    /// launch. Recording works either way.
    @discardableResult
    func requestPreciseLocationIfNeeded(purposeKey: String) -> Bool {
        guard authorizationStatus == .authorizedWhenInUse
                || authorizationStatus == .authorizedAlways,
              accuracyAuthorization == .reducedAccuracy
        else {
            return false
        }
        requestTemporaryFullAccuracyAuthorization(withPurposeKey: purposeKey)
        return true
    }
}
