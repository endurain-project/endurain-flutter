import Foundation
import CoreBluetooth

/// Minimal CoreBluetooth client that connects to a cadence sensor and exposes
/// the most recent cadence in revolutions/steps per minute.
///
/// Owned by `CoreLocationActivityRecorder` so the cadence connection has the
/// same lifetime as GPS collection, continuing in the background via the
/// `bluetooth-central` background mode. A cadence sensor advertises either the
/// Cycling Speed and Cadence service (CSC, `0x1816` / `0x2A5B`) or the Running
/// Speed and Cadence service (RSC, `0x1814` / `0x2A53`); this client discovers
/// whichever the device exposes and parses accordingly. Cycling cadence is
/// derived by differencing the cumulative crank counters between consecutive
/// notifications, so that state is kept here; running cadence is reported
/// directly.
///
/// All CoreBluetooth callbacks are delivered on the main thread, so state is
/// read and written without additional locking.
final class CadencePeripheralClient: NSObject {
    private static let cscService = CBUUID(string: "1816")
    private static let cscMeasurement = CBUUID(string: "2A5B")
    private static let rscService = CBUUID(string: "1814")
    private static let rscMeasurement = CBUUID(string: "2A53")

    /// Most recent decoded cadence in RPM (cycling) or SPM (running), or nil.
    private(set) var latestRpm: Int?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var targetIdentifier: UUID?

    // Stateful CSC crank-revolution baseline for cadence derivation.
    private var previousCrankRevolutions: Int?
    private var previousCrankEventTime: Int?

    /// Connects to [deviceIdentifier] (a CoreBluetooth peripheral UUID string)
    /// and begins streaming cadence.
    func start(deviceIdentifier: String) {
        stop()
        guard let uuid = UUID(uuidString: deviceIdentifier) else {
            return
        }
        targetIdentifier = uuid
        central = CBCentralManager(delegate: self, queue: nil)
    }

    /// Disconnects and releases the CoreBluetooth connection.
    func stop() {
        latestRpm = nil
        previousCrankRevolutions = nil
        previousCrankEventTime = nil
        if let central = central, let peripheral = peripheral {
            central.cancelPeripheralConnection(peripheral)
        }
        central?.stopScan()
        peripheral = nil
        central = nil
        targetIdentifier = nil
    }

    private func connectKnownOrScan() {
        guard let central = central, let uuid = targetIdentifier else {
            return
        }
        if let existing = central.retrievePeripherals(withIdentifiers: [uuid]).first {
            peripheral = existing
            existing.delegate = self
            central.connect(existing, options: nil)
        } else {
            central.scanForPeripherals(
                withServices: [
                    CadencePeripheralClient.cscService,
                    CadencePeripheralClient.rscService,
                ],
                options: nil
            )
        }
    }

    /// Derives cycling cadence in RPM from a CSC Measurement, differencing the
    /// crank counters against the previous sample. Returns nil on the first
    /// (baseline) sample, when no crank data is present, or when no time has
    /// elapsed (a duplicate notification, or the rider is coasting).
    private func parseCscCadenceRpm(_ data: Data) -> Int? {
        guard let crank = CadencePeripheralClient.parseCscCrank(data) else {
            return nil
        }
        let previousRevolutions = previousCrankRevolutions
        let previousEventTime = previousCrankEventTime
        previousCrankRevolutions = crank.revolutions
        previousCrankEventTime = crank.eventTime
        guard
            let baselineRevolutions = previousRevolutions,
            let baselineEventTime = previousEventTime
        else {
            return nil
        }
        let deltaRevolutions = (crank.revolutions - baselineRevolutions) & 0xFFFF
        let deltaTime = (crank.eventTime - baselineEventTime) & 0xFFFF
        if deltaTime == 0 {
            return nil
        }
        // One crank event time tick is 1/1024 s; 60 s/min * 1024 ticks/s.
        return (deltaRevolutions * 60 * 1024) / deltaTime
    }

    /// Extracts the cumulative crank revolutions (UINT16) and last crank event
    /// time (UINT16, 1/1024 s) from a CSC Measurement, or nil when the payload is
    /// truncated or carries no crank data.
    private static func parseCscCrank(_ data: Data) -> (revolutions: Int, eventTime: Int)? {
        guard !data.isEmpty else {
            return nil
        }
        let bytes = [UInt8](data)
        let flags = Int(bytes[0])
        let wheelPresent = (flags & 0x01) != 0
        let crankPresent = (flags & 0x02) != 0
        if !crankPresent {
            return nil
        }
        var offset = 1
        if wheelPresent {
            // UINT32 cumulative wheel revolutions + UINT16 last wheel event time.
            offset += 6
        }
        guard bytes.count >= offset + 4 else {
            return nil
        }
        let revolutions = Int(bytes[offset]) | (Int(bytes[offset + 1]) << 8)
        let eventTime = Int(bytes[offset + 2]) | (Int(bytes[offset + 3]) << 8)
        return (revolutions, eventTime)
    }

    /// Decodes the instantaneous cadence (UINT8, steps per minute) from an RSC
    /// Measurement, or nil when the payload is truncated.
    private func parseRscCadenceSpm(_ data: Data) -> Int? {
        guard data.count >= 4 else {
            return nil
        }
        return Int([UInt8](data)[3])
    }
}

extension CadencePeripheralClient: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            connectKnownOrScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Prefer the remembered device; keep scanning until it appears.
        if let target = targetIdentifier, peripheral.identifier != target {
            return
        }
        central.stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([
            CadencePeripheralClient.cscService,
            CadencePeripheralClient.rscService,
        ])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        latestRpm = nil
        previousCrankRevolutions = nil
        previousCrankEventTime = nil
        // Best-effort reconnect while recording continues; CoreBluetooth queues
        // the connection until the peripheral is back in range.
        if targetIdentifier != nil {
            central.connect(peripheral, options: nil)
        }
    }
}

extension CadencePeripheralClient: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            return
        }
        for service in services {
            if service.uuid == CadencePeripheralClient.cscService {
                peripheral.discoverCharacteristics(
                    [CadencePeripheralClient.cscMeasurement],
                    for: service
                )
            } else if service.uuid == CadencePeripheralClient.rscService {
                peripheral.discoverCharacteristics(
                    [CadencePeripheralClient.rscMeasurement],
                    for: service
                )
            }
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil, let characteristics = service.characteristics else {
            return
        }
        for characteristic in characteristics
        where characteristic.uuid == CadencePeripheralClient.cscMeasurement
            || characteristic.uuid == CadencePeripheralClient.rscMeasurement {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let data = characteristic.value else {
            return
        }
        if characteristic.uuid == CadencePeripheralClient.cscMeasurement {
            if let rpm = parseCscCadenceRpm(data) {
                latestRpm = rpm
            }
        } else if characteristic.uuid == CadencePeripheralClient.rscMeasurement {
            if let spm = parseRscCadenceSpm(data) {
                latestRpm = spm
            }
        }
    }
}
