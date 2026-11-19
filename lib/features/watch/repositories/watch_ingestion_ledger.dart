import 'dart:convert';

import 'package:endurain/core/services/app_preferences_store.dart';

/// Durable record of the watch sessions the phone has already ingested.
///
/// Deduplication cannot rely on the local activity record alone: the user may
/// delete that record (after it uploaded, say) while the watch still holds the
/// handoff because an acknowledgement was lost. Without this ledger the
/// re-delivered session would be stored and uploaded a second time.
///
/// Each entry also keeps the health-platform workout id the watch reported, so
/// Health Sync can skip the copy of the same workout it finds in HealthKit or
/// Health Connect.
///
/// Bounded to the [maxEntries] most recent sessions; older entries are evicted
/// first. Entries hold opaque ids only, never coordinates.
class WatchIngestionLedger {
  WatchIngestionLedger({required AppPreferencesStore preferences})
    : _preferences = preferences;

  static const String storageKey = 'endurain.watch_ingestion_ledger';
  static const int maxEntries = 1000;

  final AppPreferencesStore _preferences;
  List<_LedgerEntry>? _entries;

  /// Whether the session that maps to [localActivityId] was already ingested.
  Future<bool> contains(String localActivityId) async {
    final entries = await _load();
    return entries.any((entry) => entry.localActivityId == localActivityId);
  }

  /// Whether a watch session already covers the health-platform workout
  /// [healthWorkoutId].
  Future<bool> containsHealthWorkout(String healthWorkoutId) async {
    final entries = await _load();
    return entries.any((entry) => entry.healthWorkoutId == healthWorkoutId);
  }

  /// Records [localActivityId] (and its optional [healthWorkoutId]) as
  /// ingested. Re-recording an existing id refreshes it as the most recent.
  Future<void> record(String localActivityId, {String? healthWorkoutId}) async {
    final entries = List<_LedgerEntry>.of(await _load())
      ..removeWhere((entry) => entry.localActivityId == localActivityId)
      ..add(_LedgerEntry(localActivityId, healthWorkoutId));
    if (entries.length > maxEntries) {
      entries.removeRange(0, entries.length - maxEntries);
    }
    await _preferences.write(
      key: storageKey,
      value: jsonEncode([for (final entry in entries) entry.toJson()]),
    );
    _entries = entries;
  }

  Future<List<_LedgerEntry>> _load() async {
    final cached = _entries;
    if (cached != null) {
      return cached;
    }
    final entries = _decode(await _preferences.read(key: storageKey));
    _entries = entries;
    return entries;
  }

  static List<_LedgerEntry> _decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <_LedgerEntry>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <_LedgerEntry>[];
      }
      return [
        for (final item in decoded)
          if (item is Map && item['id'] is String)
            _LedgerEntry(
              item['id'] as String,
              item['health'] is String ? item['health'] as String : null,
            ),
      ];
    } on FormatException {
      return <_LedgerEntry>[];
    }
  }
}

class _LedgerEntry {
  const _LedgerEntry(this.localActivityId, this.healthWorkoutId);

  final String localActivityId;
  final String? healthWorkoutId;

  Map<String, Object?> toJson() => {
    'id': localActivityId,
    if (healthWorkoutId != null) 'health': healthWorkoutId,
  };
}
