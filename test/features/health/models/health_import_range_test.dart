import 'package:endurain/features/health/models/health_import_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthImportRange', () {
    test('defaults to the last 30 days', () {
      const range = HealthImportRange.defaultRange;
      final now = DateTime.utc(2026, 7, 11, 12);

      final bounds = range.resolve(now);

      expect(range.preset, HealthImportRangePreset.last30Days);
      expect(bounds.startInclusive, DateTime.utc(2026, 6, 11, 12));
      expect(bounds.endExclusive, now);
    });

    test('subtracts calendar months without overflowing month ends', () {
      const range = HealthImportRange.last3Months();
      final bounds = range.resolve(DateTime.utc(2026, 5, 31, 8, 30));

      expect(bounds.startInclusive, DateTime.utc(2026, 2, 28, 8, 30));
    });

    test('custom range includes the complete end date', () {
      final range = HealthImportRange.custom(
        startDate: DateTime(2026, 1, 5, 14),
        endDate: DateTime(2026, 1, 7, 8),
      );

      final bounds = range.resolve(DateTime.utc(2026, 7, 11));

      expect(bounds.startInclusive, DateTime(2026, 1, 5).toUtc());
      expect(bounds.endExclusive, DateTime(2026, 1, 8).toUtc());
    });

    test('rejects a custom range ending before it starts', () {
      expect(
        () => HealthImportRange.custom(
          startDate: DateTime(2026, 2, 2),
          endDate: DateTime(2026, 2, 1),
        ),
        throwsArgumentError,
      );
    });

    test('all history starts at the Unix epoch', () {
      const range = HealthImportRange.allHistory();
      final now = DateTime.utc(2026, 7, 11);

      final bounds = range.resolve(now);

      expect(bounds.startInclusive, DateTime.utc(1970));
      expect(bounds.endExclusive, now);
    });
  });
}
