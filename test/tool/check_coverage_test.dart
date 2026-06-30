import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_coverage.dart';

void main() {
  group('CoverageSummary', () {
    test('calculates line coverage from LCOV records', () {
      final summary = CoverageSummary.fromLcov([
        'SF:lib/core/example.dart',
        'LH:8',
        'LF:10',
        'end_of_record',
        'SF:lib/features/example.dart',
        'LH:2',
        'LF:5',
        'end_of_record',
      ], excludePatterns: const []);

      expect(summary.hitLines, 10);
      expect(summary.totalLines, 15);
      expect(summary.includedFiles, 2);
      expect(summary.percent, closeTo(66.67, 0.01));
    });

    test('excludes files using glob patterns', () {
      final summary = CoverageSummary.fromLcov(
        [
          'SF:lib/l10n/app_localizations_en.dart',
          'LH:0',
          'LF:100',
          'end_of_record',
          'SF:lib/features/auth/screens/login_screen.dart',
          'LH:75',
          'LF:100',
          'end_of_record',
        ],
        excludePatterns: const ['lib/l10n/app_localizations*.dart'],
      );

      expect(summary.hitLines, 75);
      expect(summary.totalLines, 100);
      expect(summary.includedFiles, 1);
      expect(summary.percent, 75);
    });

    test('tracks per-file coverage records', () {
      final summary = CoverageSummary.fromLcov([
        'SF:lib/core/example.dart',
        'LH:8',
        'LF:10',
        'end_of_record',
        'SF:lib/features/example.dart',
        'LH:2',
        'LF:5',
        'end_of_record',
      ], excludePatterns: const []);

      expect(summary.files, hasLength(2));
      final first = summary.files.first;
      expect(first.path, 'lib/core/example.dart');
      expect(first.hitLines, 8);
      expect(first.totalLines, 10);
      expect(first.percent, 80);
    });

    test('excludes files from per-file records', () {
      final summary = CoverageSummary.fromLcov(
        [
          'SF:lib/l10n/app_localizations_en.dart',
          'LH:0',
          'LF:100',
          'end_of_record',
          'SF:lib/features/auth/screens/login_screen.dart',
          'LH:75',
          'LF:100',
          'end_of_record',
        ],
        excludePatterns: const ['lib/l10n/app_localizations*.dart'],
      );

      expect(summary.files, hasLength(1));
      expect(
        summary.files.single.path,
        'lib/features/auth/screens/login_screen.dart',
      );
    });

    test('filesBelow reports offenders sorted by lowest coverage', () {
      final summary = CoverageSummary.fromLcov([
        'SF:lib/a.dart',
        'LH:9',
        'LF:10',
        'end_of_record',
        'SF:lib/b.dart',
        'LH:5',
        'LF:10',
        'end_of_record',
        'SF:lib/c.dart',
        'LH:2',
        'LF:10',
        'end_of_record',
      ], excludePatterns: const []);

      final offenders = summary.filesBelow(60);

      expect(offenders.map((file) => file.path), ['lib/c.dart', 'lib/b.dart']);
    });

    test('filesBelow ignores files without executable lines', () {
      final summary = CoverageSummary.fromLcov([
        'SF:lib/empty.dart',
        'LH:0',
        'LF:0',
        'end_of_record',
      ], excludePatterns: const []);

      expect(summary.filesBelow(60), isEmpty);
    });
  });

  group('CoverageOptions', () {
    test('parses the per-file coverage threshold', () {
      final options = CoverageOptions.parse([
        '--min-line-coverage',
        '75',
        '--min-file-line-coverage',
        '60',
      ]);

      expect(options.minimumLineCoverage, 75);
      expect(options.minimumFileLineCoverage, 60);
    });

    test('defaults thresholds to zero', () {
      final options = CoverageOptions.parse(const []);

      expect(options.minimumLineCoverage, 0);
      expect(options.minimumFileLineCoverage, 0);
    });
  });
}
