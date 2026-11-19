/// A time-ordered buffer of sensor readings that stamps the nearest value onto
/// a track point.
///
/// Readings are appended in arrival (time) order, so a binary search locates
/// the neighbours of a query timestamp; the closer of the two is returned when
/// it falls within [_freshness], else `null`.
///
/// The buffer keeps the recording's readings so finalization can re-stamp all
/// persisted points, including points delivered after a background gap. On
/// iOS, readings are persisted in the native sensor log before entering this
/// buffer, then restored from that log on recovery and finalization. Android
/// persists sensor values on the points themselves. Memory usage scales with
/// recording duration; [clear] releases readings when their session is cleared
/// or replaced.
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
