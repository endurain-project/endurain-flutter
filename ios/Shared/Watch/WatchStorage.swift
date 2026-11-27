import Foundation

/// File locations and attributes shared by the phone and watch apps.
enum WatchStorage {
    /// The app's Application Support directory, or the temporary directory in
    /// the unlikely case the system does not provide one.
    static var applicationSupportDirectory: URL {
        return FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
    }

    /// Keeps [directory] out of device and iCloud backups. Workout routes and
    /// heart rate are health data.
    static func excludeFromBackup(_ directory: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableDirectory = directory
        try mutableDirectory.setResourceValues(values)
    }
}
