import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/core/theme/app_theme_tokens.dart';
import 'package:endurain/core/theme/brand_colors.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrandColors', () {
    test('light and dark resolve the brand accent for their surface', () {
      expect(BrandColors.light.brand, AppThemeTokens.brand);
      // Base teal is too dark on dark surfaces, so it uses the foreground.
      expect(BrandColors.dark.brand, AppThemeTokens.brandDarkForeground);
    });

    test('semantic accents are identical in light and dark', () {
      expect(BrandColors.light.hr, BrandColors.dark.hr);
      expect(BrandColors.light.effort, BrandColors.dark.effort);
      expect(BrandColors.light.info, BrandColors.dark.info);
      expect(BrandColors.light.goal, BrandColors.dark.goal);
    });

    test('hairline differs between light and dark', () {
      expect(BrandColors.light.hairline, AppThemeTokens.hairlineLight);
      expect(BrandColors.dark.hairline, AppThemeTokens.hairlineDark);
    });

    test('copyWith overrides only the provided field', () {
      const override = Color(0xFF123456);
      final result = BrandColors.light.copyWith(hr: override);

      expect(result.hr, override);
      expect(result.brand, BrandColors.light.brand);
      expect(result.effort, BrandColors.light.effort);
      expect(result.hairline, BrandColors.light.hairline);
    });

    test('lerp returns endpoints at t=0 and t=1', () {
      const start = BrandColors.light;
      const end = BrandColors.dark;

      expect(start.lerp(end, 0).brand, start.brand);
      expect(start.lerp(end, 1).brand, end.brand);
      expect(start.lerp(end, 1).hairline, end.hairline);
    });

    test('lerp interpolates between the two brand colors', () {
      final mid = BrandColors.light.lerp(BrandColors.dark, 0.5);

      expect(
        mid.brand,
        Color.lerp(BrandColors.light.brand, BrandColors.dark.brand, 0.5),
      );
    });

    test('lerp ignores a mismatched extension type', () {
      expect(BrandColors.light.lerp(null, 0.5), same(BrandColors.light));
    });

    testWidgets('of returns the Material extension when present', (
      tester,
    ) async {
      late BrandColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              resolved = BrandColors.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, BrandColors.light);
    });

    testWidgets('of falls back to platform brightness without a theme', (
      tester,
    ) async {
      late BrandColors resolved;
      await tester.pumpWidget(
        CupertinoApp(
          home: MediaQuery(
            data: const MediaQueryData(platformBrightness: Brightness.dark),
            child: Builder(
              builder: (context) {
                resolved = BrandColors.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(resolved, BrandColors.dark);
    });
  });
}
