import 'package:material_ui/material_ui.dart';
import 'package:endurain/core/theme/app_theme_tokens.dart';

/// Brand and semantic-accent colors that have no direct `ColorScheme` slot.
///
/// Exposed as a [ThemeExtension] so Material widgets can read dark-aware brand
/// colors via `Theme.of(context).extension<BrandColors>()`. For platform-neutral
/// access that also works under `CupertinoApp` (iOS), prefer [BrandColors.of].
/// Data-visualization and metric accents (`hr`, `effort`, `info`, `goal`) keep
/// the same hex in both modes per the brand guidelines; the teal brand color
/// resolves to a lighter foreground on dark surfaces so it stays readable.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.brand,
    required this.brandLight,
    required this.brandMid,
    required this.brandDark,
    required this.brandDarkForeground,
    required this.brandDarkSurface,
    required this.effort,
    required this.hr,
    required this.info,
    required this.goal,
    required this.hairline,
  });

  /// Teal accent for text/icons on the current surface.
  final Color brand;
  final Color brandLight;
  final Color brandMid;
  final Color brandDark;
  final Color brandDarkForeground;
  final Color brandDarkSurface;

  /// Effort level, calories, intensity zones.
  final Color effort;

  /// Heart rate, HR zones 4–5, warnings.
  final Color hr;

  /// Distance, speed, informational states.
  final Color info;

  /// Goal completion, PRs, streaks.
  final Color goal;

  /// Hairline divider/border color (replaces card shadows).
  final Color hairline;

  static const BrandColors light = BrandColors(
    brand: AppThemeTokens.brand,
    brandLight: AppThemeTokens.brandLight,
    brandMid: AppThemeTokens.brandMid,
    brandDark: AppThemeTokens.brandDark,
    brandDarkForeground: AppThemeTokens.brandDarkForeground,
    brandDarkSurface: AppThemeTokens.brandDarkSurface,
    effort: AppThemeTokens.effort,
    hr: AppThemeTokens.hr,
    info: AppThemeTokens.info,
    goal: AppThemeTokens.goal,
    hairline: AppThemeTokens.hairlineLight,
  );

  static const BrandColors dark = BrandColors(
    // Base #1D9E75 is too dark to read on dark surfaces — use the foreground.
    brand: AppThemeTokens.brandDarkForeground,
    brandLight: AppThemeTokens.brandLight,
    brandMid: AppThemeTokens.brandMid,
    brandDark: AppThemeTokens.brandDark,
    brandDarkForeground: AppThemeTokens.brandDarkForeground,
    brandDarkSurface: AppThemeTokens.brandDarkSurface,
    effort: AppThemeTokens.effort,
    hr: AppThemeTokens.hr,
    info: AppThemeTokens.info,
    goal: AppThemeTokens.goal,
    hairline: AppThemeTokens.hairlineDark,
  );

  /// Resolves the brand palette for [context] on any platform.
  ///
  /// Uses the Material theme extension when present (Android), otherwise falls
  /// back to the platform brightness so the same colors apply under
  /// `CupertinoApp` (iOS). Never returns null, so shared widgets stay safe.
  static BrandColors of(BuildContext context) {
    final extension = Theme.of(context).extension<BrandColors>();
    if (extension != null) {
      return extension;
    }
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark ? dark : light;
  }

  @override
  BrandColors copyWith({
    Color? brand,
    Color? brandLight,
    Color? brandMid,
    Color? brandDark,
    Color? brandDarkForeground,
    Color? brandDarkSurface,
    Color? effort,
    Color? hr,
    Color? info,
    Color? goal,
    Color? hairline,
  }) {
    return BrandColors(
      brand: brand ?? this.brand,
      brandLight: brandLight ?? this.brandLight,
      brandMid: brandMid ?? this.brandMid,
      brandDark: brandDark ?? this.brandDark,
      brandDarkForeground: brandDarkForeground ?? this.brandDarkForeground,
      brandDarkSurface: brandDarkSurface ?? this.brandDarkSurface,
      effort: effort ?? this.effort,
      hr: hr ?? this.hr,
      info: info ?? this.info,
      goal: goal ?? this.goal,
      hairline: hairline ?? this.hairline,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) {
      return this;
    }
    return BrandColors(
      brand: Color.lerp(brand, other.brand, t)!,
      brandLight: Color.lerp(brandLight, other.brandLight, t)!,
      brandMid: Color.lerp(brandMid, other.brandMid, t)!,
      brandDark: Color.lerp(brandDark, other.brandDark, t)!,
      brandDarkForeground: Color.lerp(
        brandDarkForeground,
        other.brandDarkForeground,
        t,
      )!,
      brandDarkSurface: Color.lerp(
        brandDarkSurface,
        other.brandDarkSurface,
        t,
      )!,
      effort: Color.lerp(effort, other.effort, t)!,
      hr: Color.lerp(hr, other.hr, t)!,
      info: Color.lerp(info, other.info, t)!,
      goal: Color.lerp(goal, other.goal, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
    );
  }
}
