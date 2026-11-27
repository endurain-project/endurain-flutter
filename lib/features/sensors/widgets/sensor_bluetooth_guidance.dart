import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/features/sensors/controllers/sensor_section_view.dart';
import 'package:endurain/features/sensors/models/sensor_bluetooth_state.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// Explains why a sensor section cannot scan (Bluetooth off, not permitted, or
/// unsupported) and, when the fix lives in the system settings, offers a
/// button that opens them.
class SensorBluetoothGuidance extends StatelessWidget {
  const SensorBluetoothGuidance({super.key, required this.view});

  final SensorSectionView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = view.bluetoothState;
    final String message;
    var canFixInSettings = false;
    switch (state) {
      case SensorBluetoothState.off:
      case SensorBluetoothState.ready:
        message = l10n.sensorsBluetoothOff;
      case SensorBluetoothState.unauthorized:
      case SensorBluetoothState.unknown:
        // An indeterminate state after the permission request most often means
        // access was not granted; guide the user to allow it rather than
        // asserting a definitive (and possibly wrong) "off".
        message = l10n.sensorsBluetoothUnauthorized;
        canFixInSettings = !view.permissionUnavailable;
      case SensorBluetoothState.unsupported:
        message = l10n.sensorsBluetoothUnsupported;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdaptiveListSection(
          children: [
            AdaptiveListTile(
              leading: const AdaptiveIcon(
                materialIcon: Icons.bluetooth_disabled,
                cupertinoIcon: CupertinoIcons.bluetooth,
              ),
              title: message,
            ),
          ],
        ),
        if (canFixInSettings) ...[
          const SizedBox(height: UIConstants.paddingStandard),
          SensorOpenSettingsButton(view: view),
        ],
      ],
    );
  }
}

/// Button that opens the app's system settings so the user can grant the
/// Bluetooth permission that the system prompt will no longer show.
class SensorOpenSettingsButton extends StatelessWidget {
  const SensorOpenSettingsButton({super.key, required this.view});

  final SensorSectionView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdaptiveButton(
      label: l10n.activityOpenSettings,
      variant: AdaptiveButtonVariant.secondary,
      expand: true,
      onPressed: view.openAppSettings,
    );
  }
}

/// Shown under the scan button after a scan was blocked by a denied
/// permission: the reason plus the way out through the system settings.
class SensorPermissionDeniedNotice extends StatelessWidget {
  const SensorPermissionDeniedNotice({super.key, required this.view});

  final SensorSectionView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: UIConstants.paddingCompact),
          child: Text(
            l10n.sensorsPermissionRequired,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
        const SizedBox(height: UIConstants.paddingCompact),
        SensorOpenSettingsButton(view: view),
      ],
    );
  }
}
