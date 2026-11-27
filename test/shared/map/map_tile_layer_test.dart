import 'package:endurain/core/constants/map_constants.dart';
import 'package:endurain/shared/map/map_tile_layer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fake_url_launcher_service.dart';

void main() {
  group('resolveTileAttribution', () {
    test('credits OpenStreetMap for the default source', () {
      expect(
        resolveTileAttribution(
          tileServerUrl: MapConstants.defaultTileServerUrl,
        ),
        MapAttributionConstants.openStreetMapText,
      );
    });

    test('prefers the configured attribution for a custom source', () {
      expect(
        resolveTileAttribution(
          tileServerUrl: 'https://tiles.example/{z}/{x}/{y}.png',
          attribution: ' Example Maps ',
        ),
        'Example Maps',
      );
    });

    test('falls back to the host for a custom source without attribution', () {
      expect(
        resolveTileAttribution(
          tileServerUrl: 'https://{s}.tiles.example/{z}/{x}/{y}.png',
        ),
        '© {s}.tiles.example'.replaceAll(RegExp(r'[{}]'), ''),
      );
    });
  });

  Future<void> pumpMap(
    WidgetTester tester, {
    required String url,
    String? attribution,
    required FakeUrlLauncherService launcher,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 3,
            ),
            children: buildMapTileLayers(
              tileServerUrl: url,
              attribution: attribution,
              urlLauncher: launcher,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('OSM source renders a tile layer and a tappable credit', (
    tester,
  ) async {
    final launcher = FakeUrlLauncherService(launched: true);
    await pumpMap(
      tester,
      url: MapConstants.defaultTileServerUrl,
      launcher: launcher,
    );

    expect(find.byType(TileLayer), findsOneWidget);
    expect(find.byType(RichAttributionWidget), findsOneWidget);
    expect(find.byTooltip(MapAttributionConstants.openStreetMapText), findsOne);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('OpenStreetMap', findRichText: true));
    await tester.pump();

    expect(launcher.launchedUris, [
      MapAttributionConstants.openStreetMapCopyright,
    ]);
  });

  testWidgets('custom source shows its own attribution without a link', (
    tester,
  ) async {
    final launcher = FakeUrlLauncherService(launched: true);
    await pumpMap(
      tester,
      url: 'https://tiles.example/{z}/{x}/{y}.png',
      attribution: 'Example Maps',
      launcher: launcher,
    );

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Example Maps', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.textContaining('Example Maps', findRichText: true));
    await tester.pump();

    expect(launcher.launchedUris, isEmpty);
    await tester.pump(const Duration(seconds: 30));
  });
}
