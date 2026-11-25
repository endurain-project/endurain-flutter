/// UI/Layout constants used across the app
class UIConstants {
  // Common padding values (component-internal gaps + section rhythm).
  // Aligned with the brand spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32.
  static const double paddingSmall = 4.0;
  static const double paddingCompact = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingStandard = 16.0;
  static const double paddingDetail = 20.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Tab bar
  static const double tabBarHeight = 60.0;

  // Large screens (an unfolded iPhone Duo, tablets, landscape).
  /// Widest that list sections and forms grow; wider windows centre them.
  static const double readableContentMaxWidth = 640.0;

  /// Narrowest width that shows a list and its selected item side by side.
  /// The Material "expanded" window size class, which an unfolded iPhone Duo
  /// (951pt) reaches in landscape but not in portrait (669pt).
  static const double twoPaneMinWidth = 840.0;

  /// Width of the list pane in a side-by-side layout.
  static const double listPaneWidth = 360.0;

  // Common layout values
  static const double elevationNone = 0.0;
  // Subtle depth for transient/floating surfaces (dialogs, sheets, menus).
  static const double elevationTransient = 3.0;

  // Copyright
  static const int copyrightStartYear = 2023;
}
