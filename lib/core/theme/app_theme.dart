import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:endurain/core/constants/ui_constants.dart';
import 'package:endurain/core/theme/app_theme_tokens.dart';
import 'package:endurain/core/theme/brand_colors.dart';

/// Builds the Material and Cupertino themes from the Endurain brand tokens.
///
/// Colors, radii and typography are derived from [AppThemeTokens] — the single
/// in-repo source of truth for the Endurain brand tokens. Most chrome reads
/// from the `ColorScheme` semantic roles (so it flips automatically in dark
/// mode); data/metric accents come from the [BrandColors] theme extension.
class AppTheme {
  // Material themes for Android
  static ThemeData get lightTheme => _materialTheme(
    colorScheme: _lightColorScheme,
    brandColors: BrandColors.light,
    cardColor: AppThemeTokens.lightCard,
    hairline: AppThemeTokens.hairlineLight,
  );

  static ThemeData get darkTheme => _materialTheme(
    colorScheme: _darkColorScheme,
    brandColors: BrandColors.dark,
    cardColor: AppThemeTokens.darkCard,
    hairline: AppThemeTokens.hairlineDark,
  );

  /// Light scheme pinned to the brand semantic layer, derived from the teal
  /// seed so the secondary/tertiary ramps stay harmonious.
  static final ColorScheme _lightColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppThemeTokens.primarySeed,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppThemeTokens.brand,
        onPrimary: Colors.white,
        secondary: AppThemeTokens.brandMid,
        onSecondary: Colors.white,
        secondaryContainer: AppThemeTokens.brandLight,
        onSecondaryContainer: AppThemeTokens.brandMid,
        surface: AppThemeTokens.lightBackground,
        onSurface: AppThemeTokens.ink,
        onSurfaceVariant: AppThemeTokens.lightMutedForeground,
        // Cards/dialogs/sheets are white on the warm page background.
        surfaceContainerLowest: AppThemeTokens.lightCard,
        surfaceContainerLow: AppThemeTokens.lightCard,
        surfaceContainer: AppThemeTokens.lightCard,
        surfaceContainerHigh: AppThemeTokens.lightCard,
        surfaceContainerHighest: AppThemeTokens.lightCard,
        error: AppThemeTokens.destructive,
        onError: Colors.white,
        outlineVariant: AppThemeTokens.hairlineLight,
      );

  static final ColorScheme _darkColorScheme =
      ColorScheme.fromSeed(
        seedColor: AppThemeTokens.primarySeed,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppThemeTokens.brandDarkForeground,
        onPrimary: AppThemeTokens.brandDarkSurface,
        secondary: AppThemeTokens.brandDarkForeground,
        onSecondary: AppThemeTokens.brandDarkSurface,
        secondaryContainer: AppThemeTokens.brandDarkSurface,
        onSecondaryContainer: AppThemeTokens.brandDarkForeground,
        surface: AppThemeTokens.darkBackground,
        onSurface: AppThemeTokens.darkForeground,
        onSurfaceVariant: AppThemeTokens.darkMutedForeground,
        // Transient surfaces sit one step above the dark page background.
        surfaceContainerLowest: AppThemeTokens.darkCard,
        surfaceContainerLow: AppThemeTokens.darkCard,
        surfaceContainer: AppThemeTokens.darkCard,
        surfaceContainerHigh: AppThemeTokens.darkCard,
        surfaceContainerHighest: AppThemeTokens.darkCard,
        error: AppThemeTokens.destructive,
        onError: Colors.white,
        outlineVariant: AppThemeTokens.hairlineDark,
      );

  static ThemeData _materialTheme({
    required ColorScheme colorScheme,
    required BrandColors brandColors,
    required Color cardColor,
    required Color hairline,
  }) {
    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[brandColors],
      // Flat & calm: no surface tint, no shadow on chrome.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: UIConstants.elevationNone,
        scrolledUnderElevation: UIConstants.elevationNone,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      // Cards use a hairline border instead of elevation.
      cardTheme: CardThemeData(
        elevation: UIConstants.elevationNone,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusCard),
          side: BorderSide(
            color: hairline,
            width: AppThemeTokens.hairlineWidth,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: hairline,
        thickness: AppThemeTokens.hairlineWidth,
        space: AppThemeTokens.hairlineWidth,
      ),
      // Transient surfaces keep subtle elevation for depth cues, but match the
      // card color and drop the surface tint to stay on-brand.
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: UIConstants.elevationTransient,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: UIConstants.elevationTransient,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: UIConstants.elevationTransient,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: UIConstants.elevationNone,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusInput),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppThemeTokens.focusedBorderWidth,
          ),
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: _buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: UIConstants.elevationNone,
          shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: _buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: _buttonShape),
      ),
    );
  }

  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppThemeTokens.radiusInput),
  );

  /// Typography roles from the guidelines. Only weights 400 (regular) and
  /// 500 (medium) are used — never 600/700. Headings/titles read from
  /// `onSurface`; body/labels read from the muted `onSurfaceVariant`.
  static TextTheme _textTheme(ColorScheme colorScheme) {
    final foreground = colorScheme.onSurface;
    final muted = colorScheme.onSurfaceVariant;
    return TextTheme(
      // Hero number (display 44 / 500).
      displaySmall: TextStyle(
        fontSize: AppThemeTokens.fontSizeDisplay,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      // Page title (26 / 500).
      headlineSmall: TextStyle(
        fontSize: AppThemeTokens.fontSizePageTitle,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      // Card heading / metric value (22 / 500).
      titleLarge: TextStyle(
        fontSize: AppThemeTokens.fontSizeCardHeading,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      // Section heading (18 / 500).
      titleMedium: TextStyle(
        fontSize: AppThemeTokens.fontSizeSection,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      // List item / card title (15 / 500).
      titleSmall: TextStyle(
        fontSize: AppThemeTokens.fontSizeItem,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      // Body / metadata (14 / 400, muted).
      bodyMedium: TextStyle(
        fontSize: AppThemeTokens.fontSizeBody,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      // Unit labels / hints / dense chrome (13 / 400, muted).
      bodySmall: TextStyle(
        fontSize: AppThemeTokens.fontSizeHint,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      // Section labels / metric captions (11 / 500, uppercase, tracked).
      labelSmall: TextStyle(
        fontSize: AppThemeTokens.fontSizeCaption,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: muted,
      ),
    );
  }

  // Cupertino themes for iOS/macOS. Navigation chrome stays native, but the
  // brand color and the shared type roles match the Material side so content
  // looks consistent across platforms.
  static CupertinoThemeData get cupertinoLightTheme {
    return CupertinoThemeData(
      primaryColor: AppThemeTokens.brand,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppThemeTokens.lightBackground,
      barBackgroundColor: AppThemeTokens.lightCard,
      textTheme: _cupertinoTextTheme(AppThemeTokens.ink),
    );
  }

  static CupertinoThemeData get cupertinoDarkTheme {
    return CupertinoThemeData(
      primaryColor: AppThemeTokens.brandDarkForeground,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppThemeTokens.darkBackground,
      barBackgroundColor: AppThemeTokens.darkCard,
      textTheme: _cupertinoTextTheme(AppThemeTokens.darkForeground),
    );
  }

  static CupertinoTextThemeData _cupertinoTextTheme(Color foreground) {
    return CupertinoTextThemeData(
      primaryColor: foreground,
      textStyle: TextStyle(
        fontSize: AppThemeTokens.fontSizeBody,
        fontWeight: FontWeight.w400,
        color: foreground,
      ),
      navTitleTextStyle: TextStyle(
        fontSize: AppThemeTokens.fontSizeSection,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontSize: AppThemeTokens.fontSizePageTitle,
        fontWeight: FontWeight.w500,
        color: foreground,
      ),
    );
  }
}
