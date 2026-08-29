import 'package:endurain/features/activity/models/activity_type.dart';
import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/services/activity_location_recorder.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NativeActivityRecorderChannel', () {
    const codec = StandardMethodCodec();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const methodChannel = MethodChannel(
      NativeActivityRecorderChannelContract.methodChannelName,
    );

    late List<MethodCall> calls;
    late NativeActivityRecorderChannel channel;

    setUp(() {
      calls = [];
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        switch (call.method) {
          case NativeActivityRecorderChannelContract.drain:
            return <Object?>[
              {
                't': '2026-06-03T09:00:00.000Z',
                'lat': 41.0,
                'lon': -8.0,
                'seg': 0,
              },
            ];
          case NativeActivityRecorderChannelContract.recover:
            return <Object?, Object?>{
              'localSessionId': 'session_1',
              'activityType': 'run',
              'status': 'paused',
              'startedAt': '2026-06-03T09:00:00.000Z',
            };
          default:
            return null;
        }
      });
      channel = NativeActivityRecorderChannel();
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(methodChannel, null);
    });

    test('sends versioned start arguments', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 3, 9),
        ),
      );

      final call = calls.single;
      expect(call.method, NativeActivityRecorderChannelContract.start);
      final args = call.arguments as Map;
      expect(
        args['version'],
        NativeActivityRecorderChannelContract.payloadVersion,
      );
      expect(args['localSessionId'], 'session_1');
      expect(args['activityType'], 'run');
    });

    test('includes the heart-rate device id when provided', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 3, 9),
          heartRateDeviceId: 'AA:BB:CC:DD',
        ),
      );

      final args = calls.single.arguments as Map;
      expect(args['hrDeviceId'], 'AA:BB:CC:DD');
    });

    test('omits the heart-rate device id when absent', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 3, 9),
        ),
      );

      final args = calls.single.arguments as Map;
      expect(args.containsKey('hrDeviceId'), isFalse);
    });

    test('includes the power and cadence device ids when provided', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.ride,
          startedAt: DateTime.utc(2026, 6, 3, 9),
          powerDeviceId: 'PW:11:22:33',
          cadenceDeviceId: 'CA:44:55:66',
        ),
      );

      final args = calls.single.arguments as Map;
      expect(args['powerDeviceId'], 'PW:11:22:33');
      expect(args['cadenceDeviceId'], 'CA:44:55:66');
    });

    test('omits the power and cadence device ids when absent', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.ride,
          startedAt: DateTime.utc(2026, 6, 3, 9),
        ),
      );

      final args = calls.single.arguments as Map;
      expect(args.containsKey('powerDeviceId'), isFalse);
      expect(args.containsKey('cadenceDeviceId'), isFalse);
    });

    test('includes the audio announcement config when provided', () async {
      const config = AudioAnnouncementConfig(
        enabled: true,
        duckOtherAudio: true,
        intervalUnit: AudioAnnouncementIntervalUnit.distance,
        distanceIntervalMeters: 1000,
        timeIntervalSeconds: 300,
        useImperialUnits: false,
        languageTag: 'en-US',
        distanceUnitTemplate: '{value} km',
        paceUnitTemplate: '{value} min/km',
        messageTemplate: 'Distance {distance}. Time {duration}. Pace {pace}.',
      );
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 3, 9),
          audioAnnouncementConfig: config,
        ),
      );

      final args = calls.single.arguments as Map;
      final sent = args['audioAnnouncements'] as Map;
      expect(sent['enabled'], isTrue);
      expect(sent['intervalUnit'], 'distance');
      expect(sent['distanceIntervalMeters'], 1000);
      expect(sent['languageTag'], 'en-US');
    });

    test('omits the audio announcement config when absent', () async {
      await channel.start(
        ActivityRecorderStartRequest(
          localSessionId: 'session_1',
          activityType: ActivityType.run,
          startedAt: DateTime.utc(2026, 6, 3, 9),
        ),
      );

      final args = calls.single.arguments as Map;
      expect(args.containsKey('audioAnnouncements'), isFalse);
    });

    test('invokes the expected command methods', () async {
      await channel.pause();
      await channel.resume();
      await channel.stop();
      await channel.discard();

      expect(calls.map((call) => call.method), [
        NativeActivityRecorderChannelContract.pause,
        NativeActivityRecorderChannelContract.resume,
        NativeActivityRecorderChannelContract.stop,
        NativeActivityRecorderChannelContract.discard,
      ]);
    });

    test('parses drained points', () async {
      final points = await channel.drain(sinceOffset: 0);

      expect(points, hasLength(1));
      expect(points.single.latitude, 41.0);
      expect(points.single.longitude, -8.0);
    });

    test('parses a recovered session', () async {
      final session = await channel.recoverActiveSession();

      expect(session, isNotNull);
      expect(session!.localSessionId, 'session_1');
      expect(session.activityType, ActivityType.run);
    });

    test('parses point batch events from the event channel', () async {
      final received = <ActivityRecorderEvent>[];
      final subscription = channel.events.listen(received.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await _sendEvent(codec, {
        NativeActivityRecorderChannelContract.eventType:
            NativeActivityRecorderChannelContract.eventPointBatchAvailable,
        NativeActivityRecorderChannelContract.eventPoints: <Object?>[
          {'t': '2026-06-03T09:00:01.000Z', 'lat': 41.1, 'lon': -8.6, 'seg': 0},
        ],
      });
      await pumpEventQueue();

      expect(received, hasLength(1));
      expect(
        received.single.type,
        ActivityRecorderEventType.pointBatchAvailable,
      );
      expect(received.single.points.single.latitude, 41.1);
    });

    test('parses failure events with a typed reason', () async {
      final received = <ActivityRecorderEvent>[];
      final subscription = channel.events.listen(received.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await _sendEvent(codec, {
        NativeActivityRecorderChannelContract.eventType:
            NativeActivityRecorderChannelContract.eventFailed,
        NativeActivityRecorderChannelContract.eventReason: 'permissionLost',
      });
      await pumpEventQueue();

      expect(received.single.type, ActivityRecorderEventType.failed);
      expect(
        received.single.failureReason,
        ActivityRecorderFailureReason.permissionLost,
      );
    });
  });
}

Future<void> _sendEvent(StandardMethodCodec codec, Object? payload) async {
  ServicesBinding.instance.channelBuffers.push(
    NativeActivityRecorderChannelContract.eventChannelName,
    codec.encodeSuccessEnvelope(payload),
    (_) {},
  );
}
