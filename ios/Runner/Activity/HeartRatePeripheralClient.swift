import Foundation
import CoreBluetooth

/// Minimal CoreBluetooth client that connects to a heart-rate strap and exposes
/// the most recent BPM.
///
/// Owned by `CoreLocationActivityRecorder` so the heart-rate connection has the
/// same lifetime as GPS collection, continuing in the background via the
/// `bluetooth-central` background mode. Reads the standard GATT Heart Rate
/// Service (`0x180D`) / Heart Rate Measurement characteristic (`0x2A37`).
///
/// The device identifier is the same `CBPeripheral.identifier` UUID string that
/// the Dart pairing screen (universal_ble) remembered, so the peripheral is
/// retrieved directly; a service scan is used only as a fallback.
///
/// All CoreBluetooth and CoreLocation callbacks are delivered on the main
/// thread, so `latestBpm` is read and written without additional locking.
final class HeartRatePeripheralClient: NSObject {
    private static let heartRateService = CBUUID(string: "180D")
    private static let heartRateMeasurement = CBUUID(string: "2A37")

    /// Most recent decoded heart rate in BPM, or nil when not connected.
    private(set) var latestBpm: Int?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var targetIdentifier: UUID?

    /// Connects to [deviceIdentifier] (a CoreBluetooth peripheral UUID string)
    /// and begins streaming heart rate.
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
        latestBpm = nil
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
                withServices: [HeartRatePeripheralClient.heartRateService],
                options: nil
            )
        }
    }

    private func parseHeartRate(_ data: Data) -> Int? {
        guard !data.isEmpty else {
            return nil
        }
        let bytes = [UInt8](data)
        let is16Bit = (bytes[0] & 0x01) != 0
        if is16Bit {
            guard bytes.count >= 3 else {
                return nil
            }
            return Int(bytes[1]) | (Int(bytes[2]) << 8)
        }
        guard bytes.count >= 2 else {
            return nil
        }
        return Int(bytes[1])
    }
}

extension HeartRatePeripheralClient: CBCentralManagerDelegate {
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
        peripheral.discoverServices([HeartRatePeripheralClient.heartRateService])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        latestBpm = nil
        // Best-effort reconnect while recording continues; CoreBluetooth queues
        // the connection until the peripheral is back in range.
        if targetIdentifier != nil {
            central.connect(peripheral, options: nil)
        }
    }
}

extension HeartRatePeripheralClient: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            return
        }
        for service in services
        where service.uuid == HeartRatePeripheralClient.heartRateService {
            peripheral.discoverCharacteristics(
                [HeartRatePeripheralClient.heartRateMeasurement],
                for: service
            )
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
        where characteristic.uuid == HeartRatePeripheralClient.heartRateMeasurement {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard
            error == nil,
            characteristic.uuid == HeartRatePeripheralClient.heartRateMeasurement,
            let data = characteristic.value
        else {
            return
        }
        if let bpm = parseHeartRate(data) {
            latestBpm = bpm
        }
    }
}
