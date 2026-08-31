import 'package:endurain/features/activity/models/audio_announcement_config.dart';
import 'package:endurain/features/activity/models/audio_announcement_settings.dart';
import 'package:endurain/features/activity/services/audio_announcement_preview_adapter.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = AudioAnnouncementConfig(
    enabled: true,
    duckOtherAudio: false,
    intervalUnit: AudioAnnouncementIntervalUnit.time,
    distanceIntervalMeters: 1000,
    timeIntervalSeconds: 600,
    useImperialUnits: true,
    metric: AudioAnnouncementMetric.speed,
    languageTag: 'pt-PT',
    distanceUnitTemplate: '{value} mi',
    metricUnitTemplate: '{value} mph',
    metricLabel: 'Velocidade',
    messageTemplate: '{distance} {duration} {lapMetric} {overallMetric}',
  );

  group('MethodChannelAudioAnnouncementPreviewAdapter', () {
    late List<MethodCall> calls;
    late MethodChannel channel;

    setUp(() {
      calls = [];
      channel = const MethodChannel(
        NativeActivityRecorderChannelContract.methodChannelName,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('sends the versioned config on the recorder channel', () async {
      await MethodChannelAudioAnnouncementPreviewAdapter(methodChannel: channel)
          .speakPreview(config);

      expect(calls, hasLength(1));
      expect(
        calls.single.method,
        NativeActivityRecorderChannelContract.speakAnnouncementPreview,
      );
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      expect(
        arguments['version'],
        NativeActivityRecorderChannelContract.payloadVersion,
      );
      expect(arguments['audioAnnouncements'], config.toChannelMap());
    });

    test('propagates a native rejection so the caller can report it', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            throw PlatformException(
              code: NativeActivityRecorderChannelContract.errorInvalidArguments,
            );
          });

      await expectLater(
        MethodChannelAudioAnnouncementPreviewAdapter(methodChannel: channel)
            .speakPreview(config),
        throwsA(isA<PlatformException>()),
      );
    });
  });

  test('the unsupported adapter never throws', () async {
    await const UnsupportedAudioAnnouncementPreviewAdapter().speakPreview(
      config,
    );
  });
}
