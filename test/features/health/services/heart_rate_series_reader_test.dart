import 'dart:typed_data';

import 'package:endurain/features/health/services/heart_rate_series_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('decodeHeartRateReadings', () {
    test('returns no readings for a null reply', () {
      expect(decodeHeartRateReadings(null), isEmpty);
    });

    test('decodes flat millisecond triples as UTC readings', () {
      final readings = decodeHeartRateReadings(
        Float64List.fromList([1000, 1000, 150, 2000, 4500, 152.6]),
      );

      expect(readings, hasLength(2));
      expect(readings[0].start, DateTime.utc(1970, 1, 1, 0, 0, 1));
      expect(readings[0].end, readings[0].start);
      expect(readings[0].bpm, 150);
      expect(readings[1].start.millisecondsSinceEpoch, 2000);
      expect(readings[1].end.millisecondsSinceEpoch, 4500);
      expect(readings[1].start.isUtc, isTrue);
      expect(readings[1].bpm, 152.6);
    });

    test('skips readings with non-finite values', () {
      final readings = decodeHeartRateReadings(
        Float64List.fromList([1000, 1000, double.nan, 2000, 2000, 140]),
      );

      expect(readings.map((r) => r.bpm), [140]);
    });

    test('rejects a reply that is not whole triples', () {
      expect(
        () => decodeHeartRateReadings([1000, 1000]),
        throwsFormatException,
      );
    });

    test('rejects a reply with non-numeric values', () {
      expect(
        () => decodeHeartRateReadings(['a', 1000, 150]),
        throwsFormatException,
      );
    });
  });

  group('MethodChannelHeartRateSeriesReader', () {
    const channel = MethodChannel('endurain/health_heart_rate');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test(
      'sends the window in epoch milliseconds and decodes the reply',
      () async {
        MethodCall? received;
        messenger.setMockMethodCallHandler(channel, (call) async {
          received = call;
          return Float64List.fromList([1000, 1000, 150]);
        });
        final start = DateTime.utc(2026, 11, 5, 9);
        final end = DateTime.utc(2026, 11, 5, 10);

        final readings = await const MethodChannelHeartRateSeriesReader().read(
          start: start,
          end: end,
        );

        expect(received?.method, 'readHeartRateSeries');
        expect(received?.arguments, {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': end.millisecondsSinceEpoch,
        });
        expect(readings.single.bpm, 150);
      },
    );

    test('propagates platform errors so the caller can fall back', () {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'DEVICE_LOCKED');
      });

      expect(
        const MethodChannelHeartRateSeriesReader().read(
          start: DateTime.utc(2026),
          end: DateTime.utc(2026, 1, 2),
        ),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
