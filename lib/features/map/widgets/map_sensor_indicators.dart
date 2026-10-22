import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:endurain/core/utils/platform_utils.dart';
import 'package:endurain/features/map/controllers/map_sensor_controller.dart';
import 'package:endurain/features/sensors/models/sensor_measurement.dart';
import 'package:endurain/l10n/app_localizations.dart';
import 'package:endurain/shared/adaptive/adaptive.dart';
import 'package:material_ui/material_ui.dart';

/// Shared rounded pill container for the top-of-map indicators.
class MapPill extends StatelessWidget {
  const MapPill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isApplePlatform = PlatformUtils.isApplePlatform;
    final backgroundColor = isApplePlatform
        ? CupertinoDynamicColor.resolve(
            CupertinoTheme.of(context).barBackgroundColor,
            context,
          )
        : Theme.of(context).colorScheme.surface;
    final textColor = isApplePlatform
        ? CupertinoColors.label.resolveFrom(context)
        : Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Color(0x33000000),
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          child: child,
        ),
      ),
    );
  }
}

/// The top-of-map row of live sensor indicators.
///
/// Renders one pill per heart-rate, power, or cadence sensor that is connected
/// (live value) or searching (a remembered sensor still (re)connecting).
/// Sensors with no remembered device contribute nothing.
class MapSensorIndicators extends StatelessWidget {
  const MapSensorIndicators({super.key, required this.controllers});

  final List<MapSensorController> controllers;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (final controller in controllers) {
      switch (controller.status) {
        case MapSensorStatus.connected:
          chips.add(
            MapSensorChip(
              kind: controller.kind,
              value: controller.currentValue!,
            ),
          );
        case MapSensorStatus.searching:
          chips.add(MapSensorSearchingChip(kind: controller.kind));
        case MapSensorStatus.idle:
          break;
      }
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: chips,
    );
  }
}

/// The icon for a map sensor pill of [kind], matching the Sensors screen glyphs.
AdaptiveIcon _mapSensorIcon(SensorMeasurementKind kind) {
  return switch (kind) {
    SensorMeasurementKind.heartRate => const AdaptiveIcon(
      materialIcon: Icons.favorite,
      cupertinoIcon: CupertinoIcons.heart_fill,
      color: Color(0xFFE53935),
      size: 16,
    ),
    SensorMeasurementKind.power => const AdaptiveIcon(
      materialIcon: Icons.bolt,
      cupertinoIcon: CupertinoIcons.bolt_fill,
      size: 16,
    ),
    SensorMeasurementKind.cadence => const AdaptiveIcon(
      materialIcon: Icons.autorenew,
      cupertinoIcon: CupertinoIcons.arrow_2_circlepath,
      size: 16,
    ),
  };
}

/// The localized live value for a map sensor pill of [kind].
String _mapSensorValueLabel(
  AppLocalizations l10n,
  SensorMeasurementKind kind,
  int value,
) {
  return switch (kind) {
    SensorMeasurementKind.heartRate => l10n.sensorsBpm('$value'),
    SensorMeasurementKind.power => l10n.sensorsWatts('$value'),
    SensorMeasurementKind.cadence => l10n.sensorsRpm('$value'),
  };
}

/// Compact pill showing a live sensor value on the map.
class MapSensorChip extends StatelessWidget {
  const MapSensorChip({super.key, required this.kind, required this.value});

  final SensorMeasurementKind kind;
  final int value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapSensorIcon(kind),
          const SizedBox(width: 6),
          Text(_mapSensorValueLabel(l10n, kind, value)),
        ],
      ),
    );
  }
}

/// Compact pill shown while a remembered sensor of [kind] is being
/// (re)connected.
class MapSensorSearchingChip extends StatelessWidget {
  const MapSensorSearchingChip({super.key, required this.kind});

  final SensorMeasurementKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MapPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _mapSensorIcon(kind),
          const SizedBox(width: 6),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.sensorsScanning),
        ],
      ),
    );
  }
}
