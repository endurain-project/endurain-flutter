import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/services/app_scope.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/sensors/controllers/sensor_settings_controller.dart';
import 'package:endurain/features/sensors/models/ble_sensor_device.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/features/sensors/models/sensor_connection_status.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Settings screen to discover, connect, and monitor external heart-rate
/// sensors over Bluetooth Low Energy.
class SensorSettingsScreen extends StatefulWidget {
  const SensorSettingsScreen({super.key, this.controller});

  final SensorSettingsController? controller;

  @override
  State<SensorSettingsScreen> createState() => _SensorSettingsScreenState();
}

class _SensorSettingsScreenState extends State<SensorSettingsScreen> {
  late final SensorSettingsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final services = AppScope.servicesOf(context, listen: false);
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SensorSettingsController(service: services.heartRateSensorService);
    _controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _controller,
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
    final bluetoothReady =
        _controller.bluetoothState == SensorBluetoothState.ready;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.paddingStandard),
        child: Text(
          l10n.sensorsHeartRateHelp,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      if (bluetoothReady)
        ..._buildReadyChildren(context, l10n)
      else if (_controller.isCheckingBluetooth)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: UIConstants.paddingStandard),
          child: Center(child: AdaptiveLoadingIndicator()),
        )
      else
        AdaptiveListSection(
          header: l10n.sensorsHeartRateSection,
          children: [_buildBluetoothStateTile(l10n)],
        ),
    ];
  }

  List<Widget> _buildReadyChildren(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final status = _controller.connectionStatus;
    final isBusy =
        status == SensorConnectionStatus.connecting ||
        status == SensorConnectionStatus.reconnecting;

    if (_controller.connectionStatus == SensorConnectionStatus.connected) {
      return [
        AdaptiveListSection(
          header: l10n.sensorsHeartRateSection,
          children: [_buildConnectedTile(context, l10n)],
        ),
        const SizedBox(height: UIConstants.paddingStandard),
        AdaptiveButton(
          label: l10n.sensorsDisconnect,
          variant: AdaptiveButtonVariant.secondary,
          expand: true,
          onPressed: _controller.disconnect,
        ),
      ];
    }

    final remembered = _controller.rememberedDevice;
    return [
      if (remembered != null)
        AdaptiveListSection(
          header: l10n.sensorsSavedSection,
          children: [_buildRememberedTile(l10n, remembered, isBusy: isBusy)],
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
        label: _controller.isScanning ? l10n.sensorsStopScan : l10n.sensorsScan,
        icon: _controller.isScanning
            ? null
            : const AdaptiveIcon(
                materialIcon: Icons.bluetooth_searching,
                cupertinoIcon: CupertinoIcons.bluetooth,
              ),
        expand: true,
        onPressed: isBusy
            ? null
            : (_controller.isScanning
                  ? _controller.stopScan
                  : _controller.startScan),
      ),
      if (_controller.permissionDenied)
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.paddingCompact),
          child: Text(
            l10n.sensorsPermissionRequired,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: UIConstants.paddingStandard),
      ..._buildScanResults(context, l10n),
    ];
  }

  List<Widget> _buildScanResults(BuildContext context, AppLocalizations l10n) {
    if (_controller.isScanning && _controller.scanResults.isEmpty) {
      final scanningStyle = PlatformUtils.isApplePlatform
          ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.label.resolveFrom(context),
            )
          : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            );
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
    if (_controller.scanResults.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: UIConstants.paddingCompact,
          ),
          child: Center(
            child: AdaptiveEmptyStateText(message: l10n.sensorsNoDevices),
          ),
        ),
      ];
    }
    return [
      AdaptiveListSection(
        header: l10n.sensorsAvailableSection,
        children: _controller.scanResults
            .map((device) => _buildScanResultTile(l10n, device))
            .toList(growable: false),
      ),
    ];
  }

  Widget _buildBluetoothStateTile(AppLocalizations l10n) {
    final String message;
    switch (_controller.bluetoothState) {
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

  Widget _buildConnectedTile(BuildContext context, AppLocalizations l10n) {
    final bpm = _controller.currentBpm;
    return AdaptiveListTile(
      leading: AdaptiveIcon(
        materialIcon: Icons.favorite,
        cupertinoIcon: CupertinoIcons.heart_fill,
        color: Theme.of(context).colorScheme.error,
      ),
      title: _deviceName(_controller.connectedDevice, l10n),
      subtitle: l10n.sensorsConnected,
      trailing: Text(
        bpm != null ? l10n.sensorsBpm(bpm.toString()) : '—',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildRememberedTile(
    AppLocalizations l10n,
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
              onPressed: _controller.forget,
            ),
      onTap: isBusy ? null : () => _controller.connect(device),
    );
  }

  Widget _buildScanResultTile(AppLocalizations l10n, BleSensorDevice device) {
    final status = _controller.connectionStatus;
    final isBusy =
        status == SensorConnectionStatus.connecting ||
        status == SensorConnectionStatus.reconnecting;
    // The service marks the in-flight device as the connected device as soon as
    // a connect starts, so a spinner can be shown on the exact tapped sensor.
    final isConnecting =
        status == SensorConnectionStatus.connecting &&
        _controller.connectedDevice?.id == device.id;
    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.favorite_border,
        cupertinoIcon: CupertinoIcons.heart,
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
      onTap: isBusy ? null : () => _controller.connect(device),
    );
  }

  String _deviceName(BleSensorDevice? device, AppLocalizations l10n) {
    if (device == null || device.name.trim().isEmpty) {
      return l10n.sensorsUnknownDevice;
    }
    return device.name;
  }
}
