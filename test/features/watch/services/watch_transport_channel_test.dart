import 'package:endurain/features/watch/models/watch_link_status.dart';
import 'package:endurain/features/watch/models/watch_transport_event.dart';
import 'package:endurain/features/watch/services/watch_transport_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const methodChannel = MethodChannel(
    WatchTransportChannelContract.methodChannelName,
  );
  const eventChannel = EventChannel(
    WatchTransportChannelContract.eventChannelName,
  );

  Map<String, Object?> handoffPayload(String sessionId) => {
    'version': WatchTransportChannelContract.payloadVersion,
    'source': 'wearOs',
    'complete': true,
    'session': {
      'localSessionId': sessionId,
      'activityType': 'run',
      'status': 'completed',
      'startedAt': '2026-06-03T09:00:00.000Z',
    },
    'points': [
      {'t': '2026-06-03T09:00:00.000Z', 'lat': 41.0, 'lon': -8.0, 'seg': 0},
    ],
  };

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
  });

  group('MethodChannelWatchTransport', () {
    test('maps the native link status', () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => 'connected',
      );

      final transport = MethodChannelWatchTransport();

      expect(await transport.linkStatus(), WatchLinkStatus.connected);
    });

    test('falls back to unsupported for an unknown status', () async {
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => 'something-new',
      );

      final transport = MethodChannelWatchTransport();

      expect(await transport.linkStatus(), WatchLinkStatus.unsupported);
    });

    test('drains handoffs and skips unreadable envelopes', () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        if (call.method == WatchTransportChannelContract.drainHandoffs) {
          return <Object?>[
            handoffPayload('session_1'),
            {'version': 999, 'source': 'wearOs'},
            'not-a-map',
          ];
        }
        return null;
      });

      final transport = MethodChannelWatchTransport();
      final handoffs = await transport.drainPendingHandoffs();

      expect(handoffs, hasLength(1));
      expect(handoffs.single.sessionId, 'session_1');
    });

    test('sends the session id when acknowledging', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return null;
      });

      await MethodChannelWatchTransport().acknowledgeHandoff('session_1');

      expect(
        calls.single.method,
        WatchTransportChannelContract.acknowledgeHandoff,
      );
      final arguments = calls.single.arguments as Map<Object?, Object?>;
      final sessionId = arguments[WatchTransportChannelContract.argSessionId];
      expect(sessionId, 'session_1');
      expect(
        arguments[WatchTransportChannelContract.argVersion],
        WatchTransportChannelContract.payloadVersion,
      );
    });

    test('does not activate the event stream when unsupported', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        calls.add(call);
        return 'unsupported';
      });

      final transport = MethodChannelWatchTransport();

      expect(await transport.events.toList(), isEmpty);
      expect(
        calls.map((call) => call.method),
        [WatchTransportChannelContract.linkStatus],
      );
    });

    test('stays inert when the native transport is absent', () async {
      // No mock handler registered: every invocation raises
      // MissingPluginException, which the adapter must absorb.
      final transport = MethodChannelWatchTransport();

      expect(await transport.linkStatus(), WatchLinkStatus.unsupported);
      expect(await transport.drainPendingHandoffs(), isEmpty);
      expect(await transport.events.toList(), isEmpty);
      await expectLater(transport.acknowledgeHandoff('session_1'), completes);
    });

    test('keeps the push stream alive after a probe failure', () async {
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        throw PlatformException(
          code: WatchTransportChannelContract.errorStoreReadFailed,
        );
      });
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {
            sink.success({
              WatchTransportChannelContract.eventType:
                  WatchTransportChannelContract.eventHandoffAvailable,
            });
            sink.endOfStream();
          },
        ),
      );
      addTearDown(() => messenger.setMockStreamHandler(eventChannel, null));

      final transport = MethodChannelWatchTransport();
      final events = await transport.events.toList();

      expect(
        events.map((event) => event.type),
        [WatchTransportEventType.handoffAvailable],
      );
    });

    test('cancels the native subscription on dispose', () async {
      var cancelled = false;
      messenger.setMockMethodCallHandler(
        methodChannel,
        (call) async => 'connected',
      );
      messenger.setMockStreamHandler(
        eventChannel,
        MockStreamHandler.inline(
          onListen: (arguments, sink) {},
          onCancel: (arguments) {
            cancelled = true;
          },
        ),
      );
      addTearDown(() => messenger.setMockStreamHandler(eventChannel, null));

      final transport = MethodChannelWatchTransport();
      final subscription = transport.events.listen((_) {});
      await pumpEventQueue();

      await transport.dispose();

      expect(cancelled, isTrue);
      await subscription.cancel();
    });
  });
}
