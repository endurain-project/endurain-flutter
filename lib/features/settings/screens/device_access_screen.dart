import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/location/location_service.dart';
import 'package:endurain/features/health/controllers/health_sync_controller.dart';
import 'package:endurain/features/health/models/health_authorization_status.dart';
import 'package:endurain/features/health/models/health_sdk_status.dart';
import 'package:endurain/features/health/screens/health_access_screen.dart';
import 'package:endurain/features/settings/controllers/device_access_controller.dart';
import 'package:endurain/features/settings/models/bluetooth_access_state.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:endurain/shared/layout/readable_content.dart';
import 'package:endurain/shared/state/owned_controllers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

class DeviceAccessScreen extends StatefulWidget {
  const DeviceAccessScreen({
    super.key,
    this.controller,
    this.locationService,
    this.healthController,
    this.createHealthController,
    this.checkBluetoothAccess,
    this.requestBluetoothAccess,
    required this.healthSyncEnabled,
  }) : assert(
         controller != null || locationService != null,
         'Pass a controller or the location service to build one.',
       ),
       assert(
         healthController != null || createHealthController != null,
         'Pass a health controller or a factory for one.',
       );

  /// Injected controller (tests); otherwise one is built from
  /// [locationService] and owned by the screen.
  final DeviceAccessController? controller;
  final LocationService? locationService;

  /// Injected health controller (tests); otherwise built with
  /// [createHealthController] and owned by the screen.
  final HealthSyncController? healthController;
  final HealthSyncController Function()? createHealthController;
  final bool healthSyncEnabled;

  /// Read and request Bluetooth access, supplied by the composition root when
  /// the Bluetooth row is offered. Used only when this screen builds its own
  /// controller.
  final Future<BluetoothAccessState> Function()? checkBluetoothAccess;
  final Future<BluetoothAccessState> Function()? requestBluetoothAccess;

  @override
  State<DeviceAccessScreen> createState() => _DeviceAccessScreenState();
}

class _DeviceAccessScreenState extends State<DeviceAccessScreen>
    with WidgetsBindingObserver, OwnedControllers {
  late final DeviceAccessController _controller;
  late final HealthSyncController _healthController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = registerController(
      widget.controller,
      () => DeviceAccessController(
        locationService: widget.locationService!,
        checkBluetoothAccess: widget.checkBluetoothAccess,
        requestBluetoothAccess: widget.requestBluetoothAccess,
      ),
    );
    _healthController = registerController(
      widget.healthController,
      () => widget.createHealthController!(),
    );
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    await _controller.load();
    if (widget.healthSyncEnabled) {
      await _healthController.loadStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _healthController]),
      builder: (context, _) {
        return AdaptiveScaffold(
          title: l10n.deviceAccessTitle,
          body: RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: readableContentPadding(context),
              children: [
                AdaptiveListSection(
                  header: l10n.deviceAccessLocationSection,
                  children: [_buildLocationTile(l10n)],
                ),
                if (_controller.hasBluetooth) ...[
                  const SizedBox(height: UIConstants.paddingStandard),
                  AdaptiveListSection(
                    header: l10n.deviceAccessBluetoothSection,
                    children: [_buildBluetoothTile(l10n)],
                  ),
                ],
                if (widget.healthSyncEnabled) ...[
                  const SizedBox(height: UIConstants.paddingStandard),
                  AdaptiveListSection(
                    header: l10n.deviceAccessHealthSection,
                    children: [_buildHealthTile(context, l10n)],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationTile(AppLocalizations l10n) {
    final permission = _controller.locationPermission;
    final locationEnabled = _controller.isLocationServiceEnabled;
    final status = _locationStatus(l10n, locationEnabled, permission);
    final action = _locationAction(locationEnabled, permission);

    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.location_on_outlined,
        cupertinoIcon: CupertinoIcons.location,
      ),
      title: l10n.deviceAccessLocationTitle,
      subtitle: _controller.isLoading ? l10n.deviceAccessChecking : status,
      trailing: _controller.isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            )
          : null,
      onTap: _controller.isLoading ? null : action,
    );
  }

  Widget _buildBluetoothTile(AppLocalizations l10n) {
    final state = _controller.bluetoothAccess;
    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.bluetooth,
        cupertinoIcon: CupertinoIcons.bluetooth,
      ),
      title: l10n.deviceAccessBluetoothTitle,
      subtitle: _controller.isLoading
          ? l10n.deviceAccessChecking
          : _bluetoothStatus(l10n, state),
      onTap: _controller.isLoading ? null : _bluetoothAction(state),
    );
  }

  String _bluetoothStatus(AppLocalizations l10n, BluetoothAccessState state) {
    return switch (state) {
      BluetoothAccessState.ready => l10n.deviceAccessBluetoothAllowed,
      BluetoothAccessState.off => l10n.deviceAccessBluetoothOff,
      BluetoothAccessState.notDetermined =>
        l10n.deviceAccessBluetoothNotAllowed,
      BluetoothAccessState.blocked => l10n.deviceAccessBluetoothBlocked,
      BluetoothAccessState.unavailable => l10n.deviceAccessBluetoothUnavailable,
    };
  }

  VoidCallback? _bluetoothAction(BluetoothAccessState state) {
    return switch (state) {
      BluetoothAccessState.notDetermined => _controller.requestBluetoothAccess,
      BluetoothAccessState.unavailable => null,
      BluetoothAccessState.ready ||
      BluetoothAccessState.off ||
      BluetoothAccessState.blocked => _controller.openAppSettings,
    };
  }

  Widget _buildHealthTile(BuildContext context, AppLocalizations l10n) {
    return AdaptiveListTile(
      leading: const AdaptiveIcon(
        materialIcon: Icons.monitor_heart_outlined,
        cupertinoIcon: CupertinoIcons.heart,
      ),
      title: l10n.deviceAccessHealthTitle,
      subtitle: _healthStatus(l10n),
      onTap: () {
        unawaited(
          adaptivePush<void>(
            context,
            (context) => HealthAccessScreen(controller: _healthController),
          ),
        );
      },
    );
  }

  String _locationStatus(
    AppLocalizations l10n,
    bool locationEnabled,
    LocationPermission permission,
  ) {
    if (!locationEnabled) return l10n.deviceAccessLocationServicesOff;
    return switch (permission) {
      LocationPermission.always => l10n.deviceAccessLocationAlways,
      LocationPermission.whileInUse => l10n.deviceAccessLocationWhileUsing,
      LocationPermission.deniedForever => l10n.deviceAccessLocationBlocked,
      LocationPermission.denied || LocationPermission.unableToDetermine =>
        l10n.deviceAccessLocationNotAllowed,
    };
  }

  VoidCallback _locationAction(
    bool locationEnabled,
    LocationPermission permission,
  ) {
    if (!locationEnabled) return _controller.openLocationSettings;
    return switch (permission) {
      LocationPermission.denied ||
      LocationPermission.unableToDetermine => _controller.requestLocationAccess,
      LocationPermission.deniedForever ||
      LocationPermission.always ||
      LocationPermission.whileInUse => _controller.openAppSettings,
    };
  }

  String _healthStatus(AppLocalizations l10n) {
    final state = _healthController.state;
    if (state.isCheckingStatus) return l10n.deviceAccessChecking;
    if (state.error != null) return l10n.deviceAccessHealthNeedsAttention;
    return switch (state.sdkStatus) {
      HealthSdkStatus.unsupported => l10n.deviceAccessHealthUnavailable,
      HealthSdkStatus.needsProviderInstall => l10n.deviceAccessHealthRequired,
      HealthSdkStatus.available => switch (state.authStatus) {
        HealthAuthorizationStatus.granted => l10n.deviceAccessHealthSetUp,
        HealthAuthorizationStatus.denied =>
          l10n.deviceAccessHealthNeedsAttention,
        HealthAuthorizationStatus.notDetermined =>
          l10n.deviceAccessHealthNotConnected,
      },
    };
  }
}
