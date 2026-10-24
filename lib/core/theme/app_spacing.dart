/// Spacing on a 4 px grid, and the margins screens are laid out with.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Left and right margin of every phone screen.
  static const double screenMargin = md;

  /// The smallest thing a finger is asked to hit.
  static const minTouchTarget = 48.0;
}

/// Corner radii: buttons, fields, cards, the floating tab bar, and pills.
abstract final class AppRadius {
  static const sm = 8.0;
  static const button = 12.0;
  static const field = 14.0;
  static const card = 16.0;
  static const pillNav = 26.0;
  static const full = 999.0;
}

/// Control heights.
abstract final class AppSizes {
  static const buttonLarge = 52.0;
  static const buttonMedium = 44.0;
  static const buttonSmall = 36.0;
  static const pillNavHeight = 64.0;

  /// The shortest list row (person, menu item); it grows with large text.
  static const listTile = 56.0;
}
