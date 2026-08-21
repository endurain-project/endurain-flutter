import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/sensors/controllers/sensor_section_controller.dart';
import 'package:endurain/features/sensors/controllers/sensor_section_view.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

/// Settings screen to discover, connect, and monitor external Bluetooth Low
/// Energy sensors: heart-rate monitors, cycling power meters, and cadence
/// sensors. Each measurement is an independent section that can hold its own
/// connection, and only one section scans at a time.
class SensorSettingsScreen extends StatefulWidget {
  const SensorSettingsScreen({
    super.key,
    this.controller,
    this.powerController,
    this.cadenceController,
  });

  /// Heart-rate section controller. Injected in tests; built from the app scope
  /// otherwise.
  final SensorSectionController? controller;

  /// Power section controller. Injected in tests; built from the app scope
  /// otherwise.
  final SensorSectionController? powerController;

  /// Cadence section controller. Injected in tests; built from the app scope
  /// otherwise.
  final SensorSectionController? cadenceController;

  @override
  State<SensorSettingsScreen> createState() => _SensorSettingsScreenState();
}

class _SensorSettingsScreenState extends State<SensorSettingsScreen> {
  late final SensorSectionController _heartRate;
  late final SensorSectionController _power;
  late final SensorSectionController _cadence;
  late final bool _ownsHeartRate;
  late final bool _ownsPower;
  late final bool _ownsCadence;
  late final Listenable _sections;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    _ownsHeartRate = widget.controller == null;
    _ownsPower = widget.powerController == null;
    _ownsCadence = widget.cadenceController == null;
    _heartRate =
        widget.controller ??
        SensorSectionController(service: services.heartRateSensorService);
    _power =
        widget.powerController ??
        SensorSectionController(service: services.powerSensorService);
    _cadence =
        widget.cadenceController ??
        SensorSectionController(service: services.cadenceSensorService);
    _sections = Listenable.merge([_heartRate, _power, _cadence]);
    _heartRate.initialize();
    _power.initialize();
    _cadence.initialize();
  }

  @override
  void dispose() {
    if (_ownsHeartRate) {
      _heartRate.dispose();
    }
    if (_ownsPower) {
      _power.dispose();
    }
    if (_ownsCadence) {
      _cadence.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _sections,
      builder: (context, _) {
        return AdaptiveScaffold(
          title: l10n.sensorsTitle,
          body: ListView(
            padding: const EdgeInsets.all(UIConstants.paddingStandard),
            children: _buildChildren(context, l10n),
          ),
        );
      },
    );
  }

  List<Widget> _buildChildren(BuildContext context, AppLocalizations l10n) {
    // Only one section may scan at a time: the sections share the single
    // Bluetooth adapter, so a second scan would fight the first.
    final anyScanning =
        _heartRate.isScanning || _power.isScanning || _cadence.isScanning;
    final errorColor = Theme.of(context).colorScheme.error;

    return [
      ..._buildSection(
        context,
        l10n,
        view: _heartRate,
        header: l10n.sensorsHeartRateSection,
        help: l10n.sensorsHeartRateHelp,
        noDevices: l10n.sensorsNoDevices,
        connectedMaterialIcon: Icons.favorite,
        connectedCupertinoIcon: CupertinoIcons.heart_fill,
        connectedIconColor: errorColor,
        availableMaterialIcon: Icons.favorite_border,
        availableCupertinoIcon: CupertinoIcons.heart,
        formatValue: (value) => l10n.sensorsBpm('$value'),
        scanningDisabled: anyScanning && !_heartRate.isScanning,
      ),
      const SizedBox(height: UIConstants.paddingLarge),
      ..._buildSection(
        context,
        l10n,
        view: _power,
        header: l10n.sensorsPowerSection,
        help: l10n.sensorsPowerHelp,
        noDevices: l10n.sensorsNoPowerDevices,
        connectedMaterialIcon: Icons.bolt,
        connectedCupertinoIcon: CupertinoIcons.bolt_fill,
        connectedIconColor: null,
        availableMaterialIcon: Icons.bolt_outlined,
        availableCupertinoIcon: CupertinoIcons.bolt,
        formatValue: (value) => l10n.sensorsWatts('$value'),
        scanningDisabled: anyScanning && !_power.isScanning,
      ),
      const SizedBox(height: UIConstants.paddingLarge),
      ..._buildSection(
        context,
        l10n,
        view: _cadence,
        header: l10n.sensorsCadenceSection,
        help: l10n.sensorsCadenceHelp,
        noDevices: l10n.sensorsNoCadenceDevices,
        connectedMaterialIcon: Icons.autorenew,
        connectedCupertinoIcon: CupertinoIcons.arrow_2_circlepath,
        connectedIconColor: null,
        availableMaterialIcon: Icons.autorenew,
        availableCupertinoIcon: CupertinoIcons.arrow_2_circlepath,
        formatValue: (value) => l10n.sensorsRpm('$value'),
        scanningDisabled: anyScanning && !_cadence.isScanning,
      ),
    ];
  }

  List<Widget> _buildSection(
    BuildContext context,
    AppLocalizations l10n, {
    required SensorSectionView view,
    required String header,
    required String help,
    required String noDevices,
    required IconData connectedMaterialIcon,
    required IconData connectedCupertinoIcon,
    required Color? connectedIconColor,
    required IconData availableMaterialIcon,
    required IconData availableCupertinoIcon,
    required String Function(int value) formatValue,
    required bool scanningDisabled,
  }) {
    final bluetoothReady = view.bluetoothState == SensorBluetoothState.ready;
    return [
      _buildSectionHeader(context, header),
      Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.paddingStandard),
        child: Text(help, style: Theme.of(context).textTheme.bodyMedium),
      ),
      if (bluetoothReady)
        ..._buildReadyChildren(
          context,
          l10n,
          view: view,
          noDevices: noDevices,
          connectedMaterialIcon: connectedMaterialIcon,
          connectedCupertinoIcon: connectedCupertinoIcon,
          connectedIconColor: connectedIconColor,
          availableMaterialIcon: availableMaterialIcon,
          availableCupertinoIcon: availableCupertinoIcon,
          formatValue: formatValue,
          scanningDisabled: scanningDisabled,
        )
      else if (view.isCheckingBluetooth)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: UIConstants.paddingStandard),
          child: Center(child: AdaptiveLoadingIndicator()),
        )
      else
        AdaptiveListSection(children: [_buildBluetoothStateTile(l10n, view)]),
    ];
  }

  Widget _buildSectionHeader(BuildContext context, String header) {
    final style = PlatformUtils.isApplePlatform
        ? CupertinoTheme.of(context).textTheme.textStyle
              .copyWith(fontSize: 20, fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold);
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.paddingCompact),
      child: Text(header, style: style),
    );
  }

  List<Widget> _buildReadyChildren(
    BuildContext context,
    AppLocalizations l10n, {
    required SensorSectionView view,
    required String noDevices,
    required IconData connectedMaterialIcon,
    required IconData connectedCupertinoIcon,
    required Color? connectedIconColor,
    required IconData availableMaterialIcon,
    required IconData availableCupertinoIcon,
    required String Function(int value) formatValue,
    required bool scanningDisabled,
  }) {
    final status = view.connectionStatus;
    final isBusy =
        status == SensorConnectionStatus.connecting ||
        status == SensorConnectionStatus.reconnecting;

    if (status == SensorConnectionStatus.connected) {
      return [
        AdaptiveListSection(
          children: [
            _buildConnectedTile(
              context,
              l10n,
              view: view,
              materialIcon: connectedMaterialIcon,
              cupertinoIcon: connectedCupertinoIcon,
              iconColor: connectedIconColor,
              formatValue: formatValue,
            ),
          ],
        ),
        const SizedBox(height: UIConstants.paddingStandard),
        AdaptiveButton(
          label: l10n.sensorsDisconnect,
          variant: AdaptiveButtonVariant.secondary,
          expand: true,
          onPressed: view.disconnect,
        ),
      ];
    }

    final remembered = view.rememberedDevice;
    return [
      if (remembered != null)
        AdaptiveListSection(
          header: l10n.sensorsSavedSection,
          children: [
            _buildRememberedTile(l10n, view, remembered, isBusy: isBusy),
          ],
        ),
      if (status == SensorConnectionStatus.failed)
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: UIConstants.paddingCompact,
          ),
          child: Text(
            l10n.sensorsConnectionFailed,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: UIConstants.paddingStandard),
      AdaptiveButton(
        label: view.isScanning ? l10n.sensorsStopScan : l10n.sensorsScan,
        icon: view.isScanning
            ? null
            : const AdaptiveIcon(
                materialIcon: Icons.bluetooth_searching,
                cupertinoIcon: CupertinoIcons.bluetooth,
              ),
        expand: true,
        onPressed: (isBusy || scanningDisabled)
            ? null
            : (view.isScanning ? view.stopScan : view.startScan),
      ),
      if (view.permissionDenied)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.paddingCompact),
          child: Text(
            l10n.sensorsPermissionRequired,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: UIConstants.paddingStandard),
      ..._buildScanResults(
        context,
        l10n,
        view: view,
        noDevices: noDevices,
        availableMaterialIcon: availableMaterialIcon,
        availableCupertinoIcon: availableCupertinoIcon,
      ),
    ];
  }

  List<Widget> _buildScanResults(
    BuildContext context,
    AppLocalizations l10n, {
    required SensorSectionView view,
    required String noDevices,
    required IconData availableMaterialIcon,
    required IconData availableCupertinoIcon,
  }) {
    if (view.isScanning && view.scanResults.isEmpty) {
      final scanningStyle = PlatformUtils.isApplePlatform
          ? CupertinoTheme.of(context).textTheme.textStyle
                .copyWith(color: CupertinoColors.label.resolveFrom(context))
          : Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface);
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
            const SizedBox(width: UIConstants.paddingMedium),
            Text(l10n.sensorsScanning, style: scanningStyle),
          ],
        ),
      ];
    }
    if (view.scanResults.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: UIConstants.paddingCompact,
          ),
          child: Center(child: AdaptiveEmptyStateText(message: noDevices)),
        ),
      ];
    }
    return [
      AdaptiveListSection(
        header: l10n.sensorsAvailableSection,
        children: view.scanResults
            .map(
              (device) => _buildScanResultTile(
                l10n,
                view,
                device,
                materialIcon: availableMaterialIcon,
                cupertinoIcon: availableCupertinoIcon,
              ),
            )
            .toList(growable: false),
      ),
    ];
  }

  Widget _buildBluetoothStateTile(
    AppLocalizations l10n,
    SensorSectionView view,
  ) {
    final String message;
    switch (view.bluetoothState) {
      case SensorBluetoothState.off:
        message = l10n.sensorsBluetoothOff;
      case SensorBluetoothState.unauthorized:
      case SensorBluetoothState.unknown:
        // An indeterminate state after the permission request most often means
        // access was not granted; guide the user to allow it rather than
        // asserting a definitive (and possibly wrong) "off".
        message = l10n.sensorsBluetoothUnauthorized;
      case SensorBluetoothState.unsupported:
        message = l10n.sensorsBluetoothUnsupported;
      case SensorBluetoothState.ready:
        message = l10n.sensorsBluetoothOff;
    }
    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.bluetooth_disabled,
        cupertinoIcon: CupertinoIcons.bluetooth,
      ),
      title: message,
    );
  }

  Widget _buildConnectedTile(
    BuildContext context,
    AppLocalizations l10n, {
    required SensorSectionView view,
    required IconData materialIcon,
    required IconData cupertinoIcon,
    required Color? iconColor,
    required String Function(int value) formatValue,
  }) {
    final value = view.currentValue;
    return AdaptiveListTile(
      leading: AdaptiveIcon(
        materialIcon: materialIcon,
        cupertinoIcon: cupertinoIcon,
        color: iconColor,
      ),
      title: _deviceName(view.connectedDevice, l10n),
      subtitle: l10n.sensorsConnected,
      trailing: Text(
        value != null ? formatValue(value) : '—',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildRememberedTile(
    AppLocalizations l10n,
    SensorSectionView view,
    BleSensorDevice device, {
    required bool isBusy,
  }) {
    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.watch,
        cupertinoIcon: CupertinoIcons.device_phone_portrait,
      ),
      title: _deviceName(device, l10n),
      subtitle: isBusy ? l10n.sensorsConnecting : null,
      trailing: isBusy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : AdaptiveButton(
              label: l10n.sensorsForget,
              variant: AdaptiveButtonVariant.secondary,
              onPressed: view.forget,
            ),
      onTap: isBusy ? null : () => view.connect(device),
    );
  }

  Widget _buildScanResultTile(
    AppLocalizations l10n,
    SensorSectionView view,
    BleSensorDevice device, {
    required IconData materialIcon,
    required IconData cupertinoIcon,
  }) {
    final status = view.connectionStatus;
    final isBusy =
        status == SensorConnectionStatus.connecting ||
        status == SensorConnectionStatus.reconnecting;
    // The service marks the in-flight device as the connected device as soon as
    // a connect starts, so a spinner can be shown on the exact tapped sensor.
    final isConnecting =
        status == SensorConnectionStatus.connecting &&
        view.connectedDevice?.id == device.id;
    return AdaptiveListTile(
      leading: AdaptiveIcon(
        materialIcon: materialIcon,
        cupertinoIcon: cupertinoIcon,
      ),
      title: _deviceName(device, l10n),
      subtitle: isConnecting ? l10n.sensorsConnecting : l10n.sensorsConnect,
      trailing: isConnecting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : null,
      onTap: isBusy ? null : () => view.connect(device),
    );
  }

  String _deviceName(BleSensorDevice? device, AppLocalizations l10n) {
    if (device == null || device.name.trim().isEmpty) {
      return l10n.sensorsUnknownDevice;
    }
    return device.name;
  }
}
