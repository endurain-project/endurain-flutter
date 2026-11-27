import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/core/services/platform/url_launcher_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:material_ui/material_ui.dart';

/// The attribution text for a tile source: the configured [attribution] when
/// the source is not the default one, otherwise the OpenStreetMap credit. A
/// custom source with no known attribution falls back to its host name so the
/// credit is never blank.
@visibleForTesting
String resolveTileAttribution({
  required String tileServerUrl,
  String? attribution,
}) {
  final custom = attribution?.trim();
  if (custom != null && custom.isNotEmpty) {
    return custom;
  }
  if (tileServerUrl == MapConstants.defaultTileServerUrl) {
    return MapAttributionConstants.openStreetMapText;
  }
  final host = Uri.tryParse(tileServerUrl.replaceAll(RegExp(r'[{}]'), ''))
      ?.host;
  return host == null || host.isEmpty
      ? MapAttributionConstants.openStreetMapText
      : '© $host';
}

/// The layers every Endurain map starts with: the raster tile layer for
/// [tileServerUrl] and a [RichAttributionWidget] crediting the tile source.
///
/// Shared by the live map and the activity route preview so the tile setup
/// and its legally required attribution cannot drift apart. Place the result
/// first among `FlutterMap.children` (spread it); the attribution is anchored
/// to the bottom-left so it clears the map's floating action button.
///
/// The default OpenStreetMap source links to the OSM copyright page through
/// [urlLauncher]; a custom source shows [attribution] (from the server
/// settings) as plain text.
List<Widget> buildMapTileLayers({
  required String tileServerUrl,
  String? attribution,
  UrlLauncherService urlLauncher = const UrlLauncherService(),
}) {
  final text = resolveTileAttribution(
    tileServerUrl: tileServerUrl,
    attribution: attribution,
  );
  final isOpenStreetMap = text == MapAttributionConstants.openStreetMapText;
  return [
    TileLayer(
      urlTemplate: tileServerUrl,
      userAgentPackageName: MapConstants.userAgent,
    ),
    RichAttributionWidget(
      alignment: AttributionAlignment.bottomLeft,
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          text,
          onTap: isOpenStreetMap
              ? () => urlLauncher.launchExternalApplication(
                  MapAttributionConstants.openStreetMapCopyright,
                )
              : null,
        ),
      ],
      openButton: (context, open) => _AttributionButton(
        icon: Icons.info_outline,
        label: text,
        onPressed: open,
      ),
      closeButton: (context, close) => _AttributionButton(
        icon: Icons.cancel_outlined,
        label: text,
        onPressed: close,
      ),
    ),
  ];
}

class _AttributionButton extends StatelessWidget {
  const _AttributionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }
}
