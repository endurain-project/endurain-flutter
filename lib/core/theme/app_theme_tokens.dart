import 'package:flutter/material.dart';

/// Raw design tokens ported from the Endurain brand & UX guidelines
/// (`devdocs/UX_guidelines_web.md`).
///
/// This is the single source of truth for brand colors, radii and border
/// widths. Never hardcode hex values in widgets — reference these tokens or,
/// preferably, the resolved `Theme.of(context)` roles and the `BrandColors`
/// theme extension.
class AppThemeTokens {
  const AppThemeTokens._();

  // --- Brand: teal -------------------------------------------------------
  static const brandLight = Color(0xFFE1F5EE);
  static const brand = Color(0xFF1D9E75);
  static const brandMid = Color(0xFF0F6E56);
  static const brandDark = Color(0xFF085041);
  static const brandDarkForeground = Color(0xFF5DCAA5);
  static const brandDarkSurface = Color(0xFF04342C);

  /// Seed used to derive the harmonious Material color scheme.
  static const primarySeed = brand;

  // --- Semantic accents (identical in light & dark) ----------------------
  static const effort = Color(0xFFEF9F27);
  static const hr = Color(0xFFE24B4A);
  static const info = Color(0xFF378ADD);
  static const goal = Color(0xFF639922);

  // --- Neutrals (light) --------------------------------------------------
  static const lightBackground = Color(0xFFF1EFE8);
  static const lightCard = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2C2C2A);
  static const lightMutedForeground = Color(0xFF888780);

  // --- Neutrals (dark) ---------------------------------------------------
  static const darkBackground = Color(0xFF18181B);
  static const darkCard = Color(0xFF27272A);
  static const darkForeground = Color(0xFFF4F4F5);
  static const darkMutedForeground = Color(0xFFA1A1AA);

  // Kept for backwards compatibility with existing scaffold wiring.
  static const lightSurface = lightBackground;
  static const darkSurface = darkBackground;

  // --- Destructive -------------------------------------------------------
  static const destructive = hr;

  // --- Hairline borders (no shadows on cards) ----------------------------
  static const hairlineLight = Color(0x14000000); // rgba(0,0,0,0.08)
  static const hairlineDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // --- Activity badge colors ---------------------------------------------
  static const activityRunningBg = Color(0xFFFBE9E8);
  static const activityRunningText = Color(0xFFB42318);
  static const activityCyclingBg = Color(0xFFE9F4DC);
  static const activityCyclingText = Color(0xFF466E15);
  static const activitySwimmingBg = Color(0xFFE6F1FB);
  static const activitySwimmingText = Color(0xFF185FA5);
  static const activityHikingBg = Color(0xFFFAEEDA);
  static const activityHikingText = Color(0xFF854F0B);
  static const activityOtherBg = Color(0xFFF1EFE8);
  static const activityOtherText = Color(0xFF5F5E5A);

  // --- Radii -------------------------------------------------------------
  static const double radiusCard = 12.0;
  static const double radiusInput = 8.0;
  static const double radiusBadge = 20.0;

  // --- Borders -----------------------------------------------------------
  static const double focusedBorderWidth = 2.0;
  static const double hairlineWidth = 1.0;

  // --- Typography roles (shared by Material & Cupertino) -----------------
  static const double fontSizeDisplay = 44.0;
  static const double fontSizePageTitle = 26.0;
  static const double fontSizeCardHeading = 22.0;
  static const double fontSizeSection = 18.0;
  static const double fontSizeItem = 15.0;
  static const double fontSizeBody = 14.0;
  static const double fontSizeHint = 13.0;
  static const double fontSizeCaption = 11.0;
}
