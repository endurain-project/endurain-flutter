// Flutter's Objective-C headers carry no concurrency annotations; the method
// handler runs on the platform (main) thread.
@preconcurrency import Flutter
import Foundation
import HealthKit

/// One heart rate reading read from HealthKit, covering `start...end`.
///
/// HealthKit can merge equal consecutive readings into one interval, so a
/// reading is an interval rather than an instant (`start == end` otherwise).
struct HeartRateSeriesReading: Equatable, Sendable {
    let start: Date
    let end: Date
    let bpm: Double
}

/// Wire format of the readings sent to Dart: flat
/// `[startMs, endMs, bpm, startMs, endMs, bpm, ...]` triples, sorted by start.
enum HeartRateSeriesEncoding {
    /// Keeps the readings that overlap `windowStart...windowEnd`, sorted by
    /// start, and flattens them into triples. A series sample overlapping the
    /// window can hold readings outside it, which are dropped here.
    static func encode(
        _ readings: [HeartRateSeriesReading],
        windowStart: Date,
        windowEnd: Date
    ) -> [Double] {
        let kept = readings
            .filter { $0.end >= windowStart && $0.start <= windowEnd }
            .sorted { $0.start < $1.start }
        var flat: [Double] = []
        flat.reserveCapacity(kept.count * 3)
        for reading in kept {
            flat.append((reading.start.timeIntervalSince1970 * 1000).rounded())
            flat.append((reading.end.timeIntervalSince1970 * 1000).rounded())
            flat.append(reading.bpm)
        }
        return flat
    }
}

/// Reads every individual heart rate reading in a time window, for Health
/// Sync on iOS.
///
/// HealthKit stores heart rate from some recordings (for example Apple Workout,
/// or older Apple Watch workouts) as condensed series: one `HKQuantitySample`
/// with `count > 1` whose `quantity` is a single summary value. A plain
/// `HKSampleQuery`, which the `health` plugin uses, returns one value per
/// series, roughly one every five minutes. `HKQuantitySeriesSampleQuery`
/// returns each reading inside every series, and single readings as well, so
/// it replaces the plugin's heart rate read on iOS.
///
/// It reads under the heart rate read permission Health Sync already requests.
@MainActor
final class HeartRateSeriesChannel {
    static let channelName = "endurain/health_heart_rate"
    static let readMethod = "readHeartRateSeries"

    private let healthStore: HKHealthStore
    private var channel: FlutterMethodChannel?

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func register(with messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            // Flutter calls method handlers on the platform thread.
            MainActor.assumeIsolated {
                self?.handle(call, result: result)
            }
        }
        self.channel = channel
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == Self.readMethod else {
            result(FlutterMethodNotImplemented)
            return
        }
        guard let args = call.arguments as? [String: Any],
              let startMs = (args["startMs"] as? NSNumber)?.doubleValue,
              let endMs = (args["endMs"] as? NSNumber)?.doubleValue,
              startMs <= endMs
        else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "startMs and endMs are required, with startMs <= endMs",
                details: nil
            ))
            return
        }
        let start = Date(timeIntervalSince1970: startMs / 1000)
        let end = Date(timeIntervalSince1970: endMs / 1000)
        Task {
            switch await read(start: start, end: end) {
            case .success(let readings):
                let flat = HeartRateSeriesEncoding.encode(
                    readings,
                    windowStart: start,
                    windowEnd: end
                )
                let data = flat.withUnsafeBufferPointer { Data(buffer: $0) }
                result(FlutterStandardTypedData(float64: data))
            case .failure(let error):
                result(FlutterError(
                    code: Self.errorCode(for: error),
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }
    }

    /// Runs `HKQuantitySeriesSampleQuery` over every heart rate sample that
    /// overlaps `start...end`. HealthKit delivers the readings on its own
    /// background queue.
    private func read(start: Date, end: Date) async -> Result<[HeartRateSeriesReading], Error> {
        await withCheckedContinuation { continuation in
            read(start: start, end: end) { continuation.resume(returning: $0) }
        }
    }

    private func read(
        start: Date,
        end: Date,
        completion: @escaping @Sendable (Result<[HeartRateSeriesReading], Error>) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable(),
              let type = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else {
            completion(.success([]))
            return
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: []
        )
        let unit = HKUnit.count().unitDivided(by: .minute())
        let collector = SeriesCollector(completion: completion)
        let query = HKQuantitySeriesSampleQuery(
            quantityType: type,
            predicate: predicate
        ) { _, quantity, dateInterval, _, done, error in
            if let error {
                collector.fail(error)
                return
            }
            if let quantity, let dateInterval {
                collector.append(HeartRateSeriesReading(
                    start: dateInterval.start,
                    end: dateInterval.end,
                    bpm: quantity.doubleValue(for: unit)
                ))
            }
            if done {
                collector.finish()
            }
        }
        healthStore.execute(query)
    }

    /// Error codes matching the ones the `health` plugin uses, so Dart can tell
    /// a locked device from a lasting failure.
    nonisolated private static func errorCode(for error: Error) -> String {
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

/// Collects the readings a series query delivers one at a time and completes
/// exactly once, on the first error or when the query reports it is done.
///
/// `@unchecked Sendable` because HealthKit calls it from its own queue: the
/// mutable state is only touched under [lock], and the completion is Sendable.
private final class SeriesCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var readings: [HeartRateSeriesReading] = []
    private var completed = false
    private let completion: @Sendable (Result<[HeartRateSeriesReading], Error>) -> Void

    init(completion: @escaping @Sendable (Result<[HeartRateSeriesReading], Error>) -> Void) {
        self.completion = completion
    }

    func append(_ reading: HeartRateSeriesReading) {
        lock.lock()
        defer { lock.unlock() }
        if !completed {
            readings.append(reading)
        }
    }

    func fail(_ error: Error) {
        guard markCompleted() else { return }
        completion(.failure(error))
    }

    func finish() {
        lock.lock()
        let result = readings
        lock.unlock()
        guard markCompleted() else { return }
        completion(.success(result))
    }

    private func markCompleted() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if completed {
            return false
        }
        completed = true
        return true
    }
}
