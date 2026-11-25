import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/start_countdown_platform_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelStartCountdownPlatformAdapter', () {
    late List<MethodCall> calls;
    late MethodChannel channel;
    late MethodChannelStartCountdownPlatformAdapter adapter;

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
      adapter = MethodChannelStartCountdownPlatformAdapter(
        methodChannel: channel,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('sends a versioned cue on the recorder channel', () async {
      await adapter.speakCue('3', duckOtherAudio: false, languageTag: 'pt-PT');

      expect(calls, hasLength(1));
      expect(
        calls.single.method,
        NativeActivityRecorderChannelContract.speakCue,
      );
      expect(calls.single.arguments, {
        'version': NativeActivityRecorderChannelContract.payloadVersion,
        'text': '3',
        'duckOtherAudio': false,
        'languageTag': 'pt-PT',
      });
    });

    test('begins and ends the warm-up', () async {
      await adapter.beginWarmUp(countdownSeconds: 5);
      await adapter.endWarmUp();

      expect(calls.map((call) => call.method), [
        NativeActivityRecorderChannelContract.beginStartWarmUp,
        NativeActivityRecorderChannelContract.endStartWarmUp,
      ]);
    });

    test('passes the countdown length to the warm-up', () async {
      await adapter.beginWarmUp(countdownSeconds: 10);

      expect(
        calls.single.method,
        NativeActivityRecorderChannelContract.beginStartWarmUp,
      );
      expect(calls.single.arguments, {'countdownSeconds': 10});
    });
  });
}
