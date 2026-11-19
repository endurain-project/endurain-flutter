import 'package:endurain/features/watch/repositories/watch_ingestion_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_preferences_store.dart';

void main() {
  test('records ids and health workout ids', () async {
    final ledger = WatchIngestionLedger(preferences: FakePreferencesStore());

    await ledger.record('watch_wearOs_1', healthWorkoutId: 'hk-1');
    await ledger.record('watch_wearOs_2');

    expect(await ledger.contains('watch_wearOs_1'), isTrue);
    expect(await ledger.contains('watch_wearOs_2'), isTrue);
    expect(await ledger.contains('watch_wearOs_3'), isFalse);
    expect(await ledger.containsHealthWorkout('hk-1'), isTrue);
    expect(await ledger.containsHealthWorkout('hk-2'), isFalse);
  });

  test('persists across instances', () async {
    final preferences = FakePreferencesStore();
    await WatchIngestionLedger(preferences: preferences)
        .record('watch_wearOs_1', healthWorkoutId: 'hk-1');

    final reloaded = WatchIngestionLedger(preferences: preferences);

    expect(await reloaded.contains('watch_wearOs_1'), isTrue);
    expect(await reloaded.containsHealthWorkout('hk-1'), isTrue);
  });

  test('evicts the oldest entries beyond the cap', () async {
    final ledger = WatchIngestionLedger(preferences: FakePreferencesStore());

    for (var i = 0; i <= WatchIngestionLedger.maxEntries; i++) {
      await ledger.record('id_$i');
    }

    expect(await ledger.contains('id_0'), isFalse);
    expect(await ledger.contains('id_1'), isTrue);
    expect(
      await ledger.contains('id_${WatchIngestionLedger.maxEntries}'),
      isTrue,
    );
  });

  test('treats a corrupt stored value as empty', () async {
    final preferences = FakePreferencesStore();
    await preferences.write(
      key: WatchIngestionLedger.storageKey,
      value: '{not json',
    );

    final ledger = WatchIngestionLedger(preferences: preferences);

    expect(await ledger.contains('anything'), isFalse);
    await ledger.record('watch_wearOs_1');
    expect(await ledger.contains('watch_wearOs_1'), isTrue);
  });
}
