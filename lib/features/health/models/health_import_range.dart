enum HealthImportRangePreset {
  last30Days,
  last3Months,
  last6Months,
  lastYear,
  custom,
  allHistory,
}

class HealthImportRange {
  const HealthImportRange._(
    this.preset, {
    this.customStartDate,
    this.customEndDate,
  });

  const HealthImportRange.last30Days()
    : this._(HealthImportRangePreset.last30Days);

  const HealthImportRange.last3Months()
    : this._(HealthImportRangePreset.last3Months);

  const HealthImportRange.last6Months()
    : this._(HealthImportRangePreset.last6Months);

  const HealthImportRange.lastYear() : this._(HealthImportRangePreset.lastYear);

  const HealthImportRange.allHistory()
    : this._(HealthImportRangePreset.allHistory);

  factory HealthImportRange.custom({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final start = _startOfDay(startDate);
    final end = _startOfDay(endDate);
    if (end.isBefore(start)) {
      throw ArgumentError.value(
        endDate,
        'endDate',
        'Custom health import range must not end before it starts.',
      );
    }
    return HealthImportRange._(
      HealthImportRangePreset.custom,
      customStartDate: start,
      customEndDate: end,
    );
  }

  static const defaultRange = HealthImportRange.last30Days();

  final HealthImportRangePreset preset;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  HealthImportBounds resolve(DateTime now) {
    final endExclusive = now.toUtc();
    return switch (preset) {
      HealthImportRangePreset.last30Days => HealthImportBounds(
        startInclusive: endExclusive.subtract(const Duration(days: 30)),
        endExclusive: endExclusive,
      ),
      HealthImportRangePreset.last3Months => HealthImportBounds(
        startInclusive: _subtractCalendarMonths(endExclusive, 3),
        endExclusive: endExclusive,
      ),
      HealthImportRangePreset.last6Months => HealthImportBounds(
        startInclusive: _subtractCalendarMonths(endExclusive, 6),
        endExclusive: endExclusive,
      ),
      HealthImportRangePreset.lastYear => HealthImportBounds(
        startInclusive: _subtractCalendarMonths(endExclusive, 12),
        endExclusive: endExclusive,
      ),
      HealthImportRangePreset.allHistory => HealthImportBounds(
        startInclusive: DateTime.utc(1970),
        endExclusive: endExclusive,
      ),
      HealthImportRangePreset.custom => HealthImportBounds(
        startInclusive: customStartDate!.toUtc(),
        endExclusive: _startOfNextDay(customEndDate!).toUtc(),
      ),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is HealthImportRange &&
        other.preset == preset &&
        other.customStartDate == customStartDate &&
        other.customEndDate == customEndDate;
  }

  @override
  int get hashCode => Object.hash(preset, customStartDate, customEndDate);

  static DateTime _startOfDay(DateTime value) {
    return value.isUtc
        ? DateTime.utc(value.year, value.month, value.day)
        : DateTime(value.year, value.month, value.day);
  }

  static DateTime _startOfNextDay(DateTime value) {
    return value.isUtc
        ? DateTime.utc(value.year, value.month, value.day + 1)
        : DateTime(value.year, value.month, value.day + 1);
  }

  static DateTime _subtractCalendarMonths(DateTime value, int months) {
    final totalMonths = value.year * 12 + value.month - 1 - months;
    final year = totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final daysInTargetMonth = DateTime.utc(year, month + 1, 0).day;
    final day = value.day.clamp(1, daysInTargetMonth);
    return DateTime.utc(
      year,
      month,
      day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
    );
  }
}

class HealthImportBounds {
  const HealthImportBounds({
    required this.startInclusive,
    required this.endExclusive,
  });

  final DateTime startInclusive;
  final DateTime endExclusive;
}
