import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:endurain/core/services/connectivity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityService', () {
    late StreamController<List<ConnectivityResult>> changes;
    late ConnectivityService service;

    setUp(() {
      changes = StreamController<List<ConnectivityResult>>();
      service = ConnectivityService(changes: changes.stream);
    });

    tearDown(() => changes.close());

    test('emits true when any transport is active', () async {
      final emissions = <bool>[];
      final subscription = service.onOnlineChanged.listen(emissions.add);

      changes.add([ConnectivityResult.wifi]);
      changes.add([ConnectivityResult.mobile, ConnectivityResult.vpn]);
      await pumpEventQueue();

      expect(emissions, [true, true]);
      await subscription.cancel();
    });

    test('emits false when fully offline', () async {
      final emissions = <bool>[];
      final subscription = service.onOnlineChanged.listen(emissions.add);

      changes.add([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(emissions, [false]);
      await subscription.cancel();
    });

    test('maps offline-to-online transitions in order', () async {
      final emissions = <bool>[];
      final subscription = service.onOnlineChanged.listen(emissions.add);

      changes.add([ConnectivityResult.none]);
      changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(emissions, [false, true]);
      await subscription.cancel();
    });

    test('swallows platform errors instead of forwarding them', () async {
      final emissions = <bool>[];
      Object? forwardedError;
      final subscription = service.onOnlineChanged.listen(
        emissions.add,
        onError: (Object error) => forwardedError = error,
      );

      changes.addError(Exception('platform failure'));
      changes.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      expect(forwardedError, isNull);
      expect(emissions, [true]);
      await subscription.cancel();
    });
  });
}
