import 'package:endurain/features/activity/services/gpx_route_parser.dart';
import 'package:endurain/features/activity/widgets/activity_route_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('ActivityRouteMap', () {
    testWidgets('renders a map with a route polyline', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityRouteMap(
              route: GpxRoute(
                segments: [
                  [
                    LatLng(41.10, -8.60),
                    LatLng(41.11, -8.59),
                    LatLng(41.12, -8.58),
                  ],
                ],
              ),
              tileServerUrl: 'https://tile.example/{z}/{x}/{y}.png',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
    });

    testWidgets('renders safely for a single-point route', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActivityRouteMap(
              route: GpxRoute(
                segments: [
                  [LatLng(41.10, -8.60)],
                ],
              ),
              tileServerUrl: 'https://tile.example/{z}/{x}/{y}.png',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
