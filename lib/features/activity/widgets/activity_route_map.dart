import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/theme/app_theme_tokens.dart';
import 'package:endurain/features/activity/services/gpx_route_parser.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Non-interactive preview map that draws a completed activity's [route] from
/// its stored GPX, framed to the track bounds. Interaction is disabled so the
/// preview never traps scroll gestures inside the details list.
class ActivityRouteMap extends StatelessWidget {
  const ActivityRouteMap({
    super.key,
    required this.route,
    required this.tileServerUrl,
    this.height = 220,
  });

  final GpxRoute route;
  final String tileServerUrl;
  final double height;

  static const double _endpointSize = 16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = route.points;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppThemeTokens.radiusCard),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: _mapOptions(points),
          children: [
            TileLayer(
              urlTemplate: tileServerUrl,
              userAgentPackageName: MapConstants.userAgent,
            ),
            PolylineLayer(
              polylines: [
                for (final segment in route.segments)
                  if (segment.length > 1)
                    Polyline(
                      points: segment,
                      strokeWidth: ActivityRouteConstants.strokeWidth,
                      color: LocationMarkerConstants.activityBlue,
                    ),
              ],
            ),
            MarkerLayer(markers: _endpointMarkers(theme)),
          ],
        ),
      ),
    );
  }

  MapOptions _mapOptions(List<LatLng> points) {
    const interaction = InteractionOptions(flags: InteractiveFlag.none);
    if (points.length < 2) {
      return MapOptions(
        initialCenter: points.isEmpty
            ? const LatLng(
                MapConstants.defaultLatitude,
                MapConstants.defaultLongitude,
              )
            : points.first,
        initialZoom: MapConstants.initialLoadZoom,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        interactionOptions: interaction,
      );
    }
    return MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(UIConstants.paddingLarge),
      ),
      minZoom: MapConstants.minZoom,
      maxZoom: MapConstants.maxZoom,
      interactionOptions: interaction,
    );
  }

  List<Marker> _endpointMarkers(ThemeData theme) {
    final start = route.start;
    final end = route.end;
    return [
      if (start != null)
        Marker(
          point: start,
          width: _endpointSize,
          height: _endpointSize,
          child: _RouteEndpoint(color: theme.colorScheme.primary),
        ),
      if (end != null && end != start)
        Marker(
          point: end,
          width: _endpointSize,
          height: _endpointSize,
          child: _RouteEndpoint(color: theme.colorScheme.error),
        ),
    ];
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}
