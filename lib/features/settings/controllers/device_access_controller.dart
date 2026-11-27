import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/settings/models/bluetooth_access_state.dart';
import 'package:endurain/shared/state/safe_notifier.dart';
import 'package:geolocator/geolocator.dart';

class DeviceAccessController extends SafeNotifier {
  /// [checkBluetoothAccess] reads the current Bluetooth state and
  /// [requestBluetoothAccess] asks for the permission; both are supplied by
  /// the composition root. Without [checkBluetoothAccess] the screen shows no
  /// Bluetooth row.
  DeviceAccessController({
    required LocationService locationService,
    Future<BluetoothAccessState> Function()? checkBluetoothAccess,
    Future<BluetoothAccessState> Function()? requestBluetoothAccess,
  }) : _locationService = locationService,
       _checkBluetoothAccess = checkBluetoothAccess,
       _requestBluetoothAccess = requestBluetoothAccess;

  final LocationService _locationService;
  final Future<BluetoothAccessState> Function()? _checkBluetoothAccess;
  final Future<BluetoothAccessState> Function()? _requestBluetoothAccess;

  BluetoothAccessState _bluetoothAccess = BluetoothAccessState.notDetermined;

  /// Whether this controller can report Bluetooth access at all.
  bool get hasBluetooth => _checkBluetoothAccess != null;
  BluetoothAccessState get bluetoothAccess => _bluetoothAccess;

  bool _isLoading = true;
  bool _isLocationServiceEnabled = false;
  LocationPermission _locationPermission = LocationPermission.unableToDetermine;

  bool get isLoading => _isLoading;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  LocationPermission get locationPermission => _locationPermission;

  Future<void> load() async {
    _isLoading = true;
    notify();
    try {
      await _refresh();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> _refresh() async {
    try {
      _isLocationServiceEnabled = await _locationService
          .isLocationServiceEnabled();
      _locationPermission = await _locationService.checkPermission();
    } catch (_) {
      // Platform channel failure: report the state as undetermined.
      _isLocationServiceEnabled = false;
      _locationPermission = LocationPermission.unableToDetermine;
    }
    final check = _checkBluetoothAccess;
    if (check != null) {
      try {
        _bluetoothAccess = await check();
      } catch (_) {
        _bluetoothAccess = BluetoothAccessState.unavailable;
      }
    }
  }

  Future<void> requestLocationAccess() async {
    try {
      _locationPermission = await _locationService.requestPermission();
    } catch (_) {
      // Keep the previous permission state when the request itself fails.
    }
    notify();
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  Future<void> requestBluetoothAccess() async {
    final request = _requestBluetoothAccess;
    if (request == null) return;
    try {
      _bluetoothAccess = await request();
    } catch (_) {
      // Keep the previous state when the request itself fails.
    }
    notify();
  }
}
