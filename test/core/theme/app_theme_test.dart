import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/theme/app_theme.dart';
import 'package:endurain/core/theme/app_theme_tokens.dart';
import 'package:endurain/core/theme/brand_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme Material', () {
    test('light theme pins the teal brand as primary', () {
      final theme = AppTheme.lightTheme;

      expect(theme.colorScheme.primary, AppThemeTokens.brand);
      expect(theme.colorScheme.onPrimary, Colors.white);
      expect(theme.colorScheme.surface, AppThemeTokens.lightBackground);
      expect(theme.colorScheme.error, AppThemeTokens.destructive);
    });

    test('dark theme uses the readable teal foreground as primary', () {
      final theme = AppTheme.darkTheme;

      expect(theme.colorScheme.primary, AppThemeTokens.brandDarkForeground);
      expect(theme.colorScheme.surface, AppThemeTokens.darkBackground);
    });

    test('attaches the matching BrandColors extension per brightness', () {
      expect(AppTheme.lightTheme.extension<BrandColors>(), BrandColors.light);
      expect(AppTheme.darkTheme.extension<BrandColors>(), BrandColors.dark);
    });

    test('cards are flat with a hairline border (no elevation/shadow)', () {
      final card = AppTheme.lightTheme.cardTheme;

      expect(card.elevation, 0);
      expect(card.surfaceTintColor, Colors.transparent);
      final shape = card.shape! as RoundedRectangleBorder;
      expect(shape.side.color, AppThemeTokens.hairlineLight);
    });

    test('transient surfaces use the card color, not seed-derived tones', () {
      expect(
        AppTheme.lightTheme.colorScheme.surfaceContainerHigh,
        AppThemeTokens.lightCard,
      );
      expect(
        AppTheme.darkTheme.colorScheme.surfaceContainerHigh,
        AppThemeTokens.darkCard,
      );
    });

    test('cards stay flat but dialogs keep subtle elevation', () {
      expect(AppTheme.lightTheme.cardTheme.elevation, 0);
      expect(
        AppTheme.lightTheme.dialogTheme.elevation,
        UIConstants.elevationTransient,
      );
    });

    test('app bar is flat with no surface tint', () {
      final appBar = AppTheme.lightTheme.appBarTheme;

      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.surfaceTintColor, Colors.transparent);
    });

    test('typography uses only regular and medium weights', () {
      final text = AppTheme.lightTheme.textTheme;

      expect(text.headlineSmall?.fontWeight, FontWeight.w500);
      expect(text.titleSmall?.fontWeight, FontWeight.w500);
      expect(text.bodyMedium?.fontWeight, FontWeight.w400);
      expect(text.labelSmall?.fontWeight, FontWeight.w500);
    });
  });

  group('AppTheme Cupertino', () {
    test('light theme uses the teal brand as primary', () {
      expect(AppTheme.cupertinoLightTheme.primaryColor, AppThemeTokens.brand);
    });

    test('dark theme uses the readable teal foreground as primary', () {
      expect(
        AppTheme.cupertinoDarkTheme.primaryColor,
        AppThemeTokens.brandDarkForeground,
      );
    });

    test('text roles match the shared sizes and weights', () {
      final text = AppTheme.cupertinoLightTheme.textTheme;

      expect(text.textStyle.fontSize, AppThemeTokens.fontSizeBody);
      expect(text.navTitleTextStyle.fontWeight, FontWeight.w500);
      expect(
        text.navLargeTitleTextStyle.fontSize,
        AppThemeTokens.fontSizePageTitle,
      );
    });
  });
}
