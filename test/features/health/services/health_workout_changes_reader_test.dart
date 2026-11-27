import 'package:endurain/features/health/services/health_workout_changes_reader.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HealthConnectWorkoutChangesReader', () {
    test('takes a changes token for workouts', () async {
      final health = _FakeHealth(token: 'token-1');

      final token = await HealthConnectWorkoutChangesReader(health)
          .currentToken();

      expect(token, 'token-1');
      expect(health.tokenTypes, [HealthDataType.WORKOUT]);
    });

    test('fails without a token', () async {
      final reader = HealthConnectWorkoutChangesReader(_FakeHealth());

      await expectLater(reader.currentToken(), throwsStateError);
    });

    test('follows every page to the earliest changed workout', () async {
      final health = _FakeHealth(
        pages: {
          'token-1': _page(
            [
              _point(HealthDataType.WORKOUT, DateTime.utc(2025, 5, 30)),
              // Only workouts count, whatever else the token covers.
              _point(HealthDataType.HEART_RATE, DateTime.utc(2025, 5, 1)),
            ],
            next: 'token-2',
            hasMore: true,
          ),
          'token-2': _page([
            _point(HealthDataType.WORKOUT, DateTime.utc(2025, 5, 28)),
          ], next: 'token-3'),
        },
      );

      final changes = await HealthConnectWorkoutChangesReader(health)
          .changesSince('token-1');

      expect(changes.nextToken, 'token-3');
      expect(changes.earliestStart, DateTime.utc(2025, 5, 28));
      expect(changes.expired, isFalse);
    });

    test('reports no earliest start when no workout changed', () async {
      final health = _FakeHealth(
        pages: {'token-1': _page(const [], next: 'token-2')},
      );

      final changes = await HealthConnectWorkoutChangesReader(health)
          .changesSince('token-1');

      expect(changes.nextToken, 'token-2');
      expect(changes.earliestStart, isNull);
    });

    test('reports an expired token', () async {
      final health = _FakeHealth(
        pages: {'token-1': _page(const [], next: 'token-1', expired: true)},
      );

      final changes = await HealthConnectWorkoutChangesReader(health)
          .changesSince('token-1');

      expect(changes.expired, isTrue);
    });
  });

  group('decodeHealthWorkoutChanges', () {
    test('decodes the token and the earliest start in UTC', () {
      final changes = decodeHealthWorkoutChanges({
        'nextToken': 'anchors',
        'earliestStartMs': 1748736000000,
      });

      expect(changes.nextToken, 'anchors');
      expect(changes.earliestStart, DateTime.utc(2025, 6));
    });

    test('decodes a reply without changes', () {
      final changes = decodeHealthWorkoutChanges({'nextToken': 'anchors'});

      expect(changes.earliestStart, isNull);
    });

    test('treats a missing token as expired', () {
      expect(decodeHealthWorkoutChanges({'nextToken': null}).expired, isTrue);
    });

    test('rejects malformed replies', () {
      expect(() => decodeHealthWorkoutChanges(null), throwsFormatException);
      expect(
        () => decodeHealthWorkoutChanges({'nextToken': ''}),
        throwsFormatException,
      );
      expect(
        () => decodeHealthWorkoutChanges({
          'nextToken': 'anchors',
          'earliestStartMs': 'soon',
        }),
        throwsFormatException,
      );
    });
  });

  group('MethodChannelHealthWorkoutChangesReader', () {
    const channel = MethodChannel('test/health_workout_changes');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return switch (call.method) {
              'currentToken' => 'anchors-1',
              'changesSince' => {
                'nextToken': 'anchors-2',
                'earliestStartMs': 1748736000000,
              },
              _ => null,
            };
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('reads the token and the changes over the channel', () async {
      const reader = MethodChannelHealthWorkoutChangesReader(channel: channel);

      expect(await reader.currentToken(), 'anchors-1');
      final changes = await reader.changesSince('anchors-1');

      expect(changes.nextToken, 'anchors-2');
      expect(changes.earliestStart, DateTime.utc(2025, 6));
      expect(calls.last.arguments, {'token': 'anchors-1'});
    });
  });
}

HealthDataPoint _point(HealthDataType type, DateTime start) {
  return HealthDataPoint(
    uuid: '${type.name}-${start.millisecondsSinceEpoch}',
    value: NumericHealthValue(numericValue: 1),
    type: type,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: start,
    dateTo: start.add(const Duration(hours: 1)),
    sourcePlatform: HealthPlatformType.googleHealthConnect,
    sourceDeviceId: 'device',
    sourceId: 'source',
    sourceName: 'source',
  );
}

_Page _page(
  List<HealthDataPoint> points, {
  required String next,
  bool hasMore = false,
  bool expired = false,
}) {
  return _Page(points, next: next, hasMore: hasMore, expired: expired);
}

/// A changes page whose upserted data points are the given ones.
class _Page extends HealthChangesResponse {
  _Page(
    this._points, {
    required String next,
    required super.hasMore,
    required bool expired,
  }) : super(
         changes: const [],
         nextChangesToken: next,
         changesTokenExpired: expired,
       );

  final List<HealthDataPoint> _points;

  @override
  List<HealthDataPoint> get upsertedDataPoints => _points;
}

class _FakeHealth extends Health {
  _FakeHealth({this.token, this.pages = const {}});

  final String? token;
  final Map<String, HealthChangesResponse> pages;
  List<HealthDataType>? tokenTypes;

  @override
  Future<String?> getChangesToken({required List<HealthDataType> types}) async {
    tokenTypes = types;
    return token;
  }

  @override
  Future<HealthChangesResponse?> getChanges({
    required String changesToken,
    bool includeSelf = false,
  }) async => pages[changesToken];
}
