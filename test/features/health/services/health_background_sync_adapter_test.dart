import 'package:endurain/features/health/services/health_background_sync_adapter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    HealthBackgroundSyncChannelContract.channelName,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    channel.setMethodCallHandler(null);
  });

  const adapter = MethodChannelHealthBackgroundSyncAdapter();

  test('schedules and cancels the native trigger', () async {
    await adapter.setScheduled(true);
    await adapter.setScheduled(false);

    expect(calls.map((call) => call.method), ['setScheduled', 'setScheduled']);
    expect(calls.map((call) => call.arguments), [
      {'scheduled': true},
      {'scheduled': false},
    ]);
  });

  test('reports the headless run as finished', () async {
    await adapter.reportFinished(succeeded: false);

    expect(calls.single.method, 'reportFinished');
    expect(calls.single.arguments, {'succeeded': false});
  });

  test('a listening engine runs the syncs native asks for', () async {
    var runs = 0;
    await adapter.listen(() async {
      runs++;
      return true;
    });
    expect(calls.single.method, 'listen');

    final reply = await messenger.handlePlatformMessage(
      HealthBackgroundSyncChannelContract.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('run')),
      null,
    );

    expect(runs, 1);
    expect(const StandardMethodCodec().decodeEnvelope(reply!), isTrue);
  });

  test('a listening engine answers no other method', () async {
    await adapter.listen(() async => true);

    final reply = await messenger.handlePlatformMessage(
      HealthBackgroundSyncChannelContract.channelName,
      const StandardMethodCodec().encodeMethodCall(const MethodCall('other')),
      null,
    );

    expect(reply, isNull);
  });
}
