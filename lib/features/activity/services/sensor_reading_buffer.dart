/// A time-ordered buffer of sensor readings that stamps the nearest value onto
/// a track point.
///
/// Readings are appended in arrival (time) order, so a binary search locates
/// the neighbours of a query timestamp; the closer of the two is returned when
/// it falls within [_freshness], else `null`.
///
/// **Retention invariant — do not prune by age.** The buffer intentionally
/// keeps every reading for the whole recording session (it is only released by
/// [clear], called at recording start). This is required for correctness: at
/// stop, the recording service re-drains *all* persisted track points —
/// including points captured while the app was backgrounded, which are only
/// stamped at finalization — and re-stamps each one from this buffer. On
/// platforms where the recorder does not persist sensor values itself (e.g. iOS
/// heart rate, which stays on the Dart BLE connection), this buffer is the
/// *sole* source of those values, so dropping older readings would silently
/// lose heart-rate/power/cadence data from long or backgrounded activities. The
/// footprint is bounded and small: readings are only appended while actively
/// recording, at the sensors' native notification rate (~1 Hz), and cleared
/// when the next recording starts.
class SensorReadingBuffer {
  SensorReadingBuffer(this._freshness);

  final Duration _freshness;
  final List<({DateTime timestamp, int value})> _readings =
      <({DateTime timestamp, int value})>[];

  void clear() => _readings.clear();

  void add(DateTime timestamp, int value) =>
      _readings.add((timestamp: timestamp, value: value));

  /// The buffered value nearest to [timestamp] within the freshness window, or
  /// `null` when no reading is close enough.
  int? nearest(DateTime timestamp) {
    if (_readings.isEmpty) {
      return null;
    }
    var low = 0;
    var high = _readings.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_readings[mid].timestamp.isBefore(timestamp)) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    int? nearestValue;
    var nearestDiff = _freshness;
    for (final index in [low - 1, low]) {
      if (index < 0 || index >= _readings.length) {
        continue;
      }
      final diff = _readings[index].timestamp.difference(timestamp).abs();
      if (diff <= nearestDiff) {
        nearestDiff = diff;
        nearestValue = _readings[index].value;
      }
    }
    return nearestValue;
  }
}
