import 'package:endurain/features/activity/models/recording_live_activity_content.dart';
import 'package:endurain/features/activity/services/native_activity_recorder_channel.dart';
import 'package:endurain/features/activity/services/recording_live_activity_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const content = RecordingLiveActivityContent(
    localSessionId: 'session',
    title: 'Run',
    distanceLabel: 'Distance',
    distanceValue: '5.20 km',
    speedLabel: 'Pace',
    speedValue: '5:12 /km',
    pausedLabel: 'Paused',
  );

  test('sends versioned content on the recorder channel', () async {
    const channel = MethodChannel(
      NativeActivityRecorderChannelContract.methodChannelName,
    );
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await MethodChannelRecordingLiveActivityAdapter(methodChannel: channel)
        .update(content);

    expect(
      calls.single.method,
      NativeActivityRecorderChannelContract.updateLiveActivity,
    );
    expect(calls.single.arguments, {
      'version': NativeActivityRecorderChannelContract.payloadVersion,
      'localSessionId': 'session',
      'title': 'Run',
      'distanceLabel': 'Distance',
      'distanceValue': '5.20 km',
      'speedLabel': 'Pace',
      'speedValue': '5:12 /km',
      'pausedLabel': 'Paused',
    });
  });

  test('the unsupported adapter does nothing', () async {
    await const UnsupportedRecordingLiveActivityAdapter().update(content);
  });

  test('equal content compares equal', () {
    expect(
      content,
      const RecordingLiveActivityContent(
        localSessionId: 'session',
        title: 'Run',
        distanceLabel: 'Distance',
        distanceValue: '5.20 km',
        speedLabel: 'Pace',
        speedValue: '5:12 /km',
        pausedLabel: 'Paused',
      ),
    );
    expect(content.hashCode, isNot(0));
  });
}
