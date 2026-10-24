import 'package:flutter/painting.dart';

/// Text styles by role, in Plus Jakarta Sans (bundled static weights 400 to 700). Colour
/// is left to the theme, so a style never carries a hue. Figures in [number]
/// and [code] are tabular, so amounts and IDs line up in a column.
abstract final class AppTextStyles {
  static const family = 'PlusJakartaSans';

  static TextStyle _style(
    double size,
    double line,
    FontWeight weight, {
    double letterSpacing = 0,
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: line / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  static final TextStyle display = _style(32, 40, FontWeight.w700);
  static final TextStyle headlineLg = _style(24, 32, FontWeight.w700);
  static final TextStyle headlineMd = _style(20, 28, FontWeight.w600);
  static final TextStyle headlineSm = _style(18, 24, FontWeight.w600);
  static final TextStyle bodyLg = _style(16, 24, FontWeight.w400);
  static final TextStyle bodyMd = _style(14, 20, FontWeight.w400);
  static final TextStyle bodySm = _style(13, 18, FontWeight.w400);
  static final TextStyle labelLg = _style(14, 20, FontWeight.w600);
  static final TextStyle labelMd = _style(12, 16, FontWeight.w600);

  /// Section labels such as "MONTHLY CONSISTENCY"; callers upper-case the text.
  static final TextStyle labelSm = _style(11, 14, FontWeight.w700, letterSpacing: 0.6);

  /// Amounts: ₹1,24,500.00.
  static final TextStyle number = _style(16, 24, FontWeight.w600, tabular: true);

  /// IDs and references: UID STU-2291, UPI refs.
  static final TextStyle code = _style(13, 18, FontWeight.w500, tabular: true);
}
