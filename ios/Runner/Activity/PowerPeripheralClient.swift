import Foundation
import CoreBluetooth

/// Minimal CoreBluetooth client that connects to a cycling power meter and
/// exposes the most recent power in watts.
///
/// Owned by `CoreLocationActivityRecorder` so the power connection has the same
/// lifetime as GPS collection, continuing in the background via the
/// `bluetooth-central` background mode. Reads the standard GATT Cycling Power
/// Service (`0x1818`) / Cycling Power Measurement characteristic (`0x2A63`).
///
/// The device identifier is the same `CBPeripheral.identifier` UUID string that
/// the Dart pairing screen (universal_ble) remembered, so the peripheral is
/// retrieved directly; a service scan is used only as a fallback.
///
/// All CoreBluetooth callbacks are delivered on the main thread, so `latestWatts`
/// is read and written without additional locking.
final class PowerPeripheralClient: NSObject {
    private static let cyclingPowerService = CBUUID(string: "1818")
    private static let cyclingPowerMeasurement = CBUUID(string: "2A63")

    /// Most recent decoded instantaneous power in watts, or nil when not connected.
    private(set) var latestWatts: Int?

    private var central: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var targetIdentifier: UUID?

    /// Connects to [deviceIdentifier] (a CoreBluetooth peripheral UUID string)
    /// and begins streaming power.
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
        latestWatts = nil
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
                withServices: [PowerPeripheralClient.cyclingPowerService],
                options: nil
            )
        }
    }

    /// Decodes the Cycling Power Measurement value: a UINT16 flags field then the
    /// instantaneous power as a SINT16 (little-endian) in watts. Negative power
    /// is clamped to zero. Returns nil for malformed data.
    private func parsePowerWatts(_ data: Data) -> Int? {
        guard data.count >= 4 else {
            return nil
        }
        let bytes = [UInt8](data)
        let raw = Int(bytes[2]) | (Int(bytes[3]) << 8)
        let signed = (raw & 0x8000) != 0 ? raw - 0x10000 : raw
        return signed < 0 ? 0 : signed
    }
}

extension PowerPeripheralClient: CBCentralManagerDelegate {
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
        peripheral.discoverServices([PowerPeripheralClient.cyclingPowerService])
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        latestWatts = nil
        // Best-effort reconnect while recording continues; CoreBluetooth queues
        // the connection until the peripheral is back in range.
        if targetIdentifier != nil {
            central.connect(peripheral, options: nil)
        }
    }
}

extension PowerPeripheralClient: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else {
            return
        }
        for service in services
        where service.uuid == PowerPeripheralClient.cyclingPowerService {
            peripheral.discoverCharacteristics(
                [PowerPeripheralClient.cyclingPowerMeasurement],
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
        where characteristic.uuid == PowerPeripheralClient.cyclingPowerMeasurement {
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
            characteristic.uuid == PowerPeripheralClient.cyclingPowerMeasurement,
            let data = characteristic.value
        else {
            return
        }
        if let watts = parsePowerWatts(data) {
            latestWatts = watts
        }
    }
}
