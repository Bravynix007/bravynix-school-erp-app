import 'package:flutter/material.dart';

/// "Warm Campus Harmony" colour tokens, named by job, never by hue. Only the
/// accent follows the theme switch ([AppAccent]); neutrals and status colours
/// are fixed, so a present mark or an overdue fee never changes meaning.
abstract final class AppColors {
  // Surfaces
  static const canvas = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEFEDE7);

  // Text
  static const ink = Color(0xFF16222C);
  static const inkSecondary = Color(0xFF56626C);
  static const inkTertiary = Color(0xFF616B74);
  static const disabled = Color(0xFF9AA3AA);

  // Lines
  /// Cards, outlined buttons and chips: decoration, not a control boundary.
  static const border = Color(0xFFE0DDD5);

  /// The outline of a text field. A field's edge must be 3:1 against what it
  /// sits on (WCAG 1.4.11), which [border] is not.
  static const fieldBorder = Color(0xFF80878D);
  static const divider = Color(0xFFECE9E2);

  // Status: one value each, whatever the screen.
  static const success = Color(0xFF1E7347);
  static const successBg = Color(0xFFE6F2EA);
  static const warning = Color(0xFF9A5407);
  static const warningBg = Color(0xFFFBEFDF);
  static const error = Color(0xFFB3261E);
  static const errorBg = Color(0xFFFBE9E8);
  static const info = Color(0xFF2B5A94);
  static const infoBg = Color(0xFFE7EEF7);

  // Attendance (PRD attendance marks; never themed).
  static const Color present = success;
  static const Color absent = error;
  static const Color late = warning;
  static const halfDay = Color(0xFF6B4FA0);
  static const Color leave = info;
  static const holiday = Color(0xFFFBA86F);
  static const Color onHoliday = ink;
}

/// The seven theme accents (UI alignment spec, Theme switch). The four light
/// originals are darkened so white text on the header and primary buttons
/// passes WCAG AA (4.5:1).
enum AppAccent {
  teal('BravyNix Teal', Color(0xFF0E5E5A)),
  forestGreen('Forest Green', Color(0xFF3A8163)),
  royalPurple('Royal Purple', Color(0xFF8465B7)),
  steelBlue('Steel Blue', Color(0xFF3A79AD)),
  rosePink('Rose Pink', Color(0xFFC84277)),
  sunsetOrange('Sunset Orange', Color(0xFFB15F1F)),
  darkCyan('Dark Cyan', Color(0xFF327F7F));

  new(this.label, this.primary);

  static const AppAccent defaultAccent = AppAccent.teal;

  final String label;

  /// Header, primary buttons, active tab and focus ring.
  final Color primary;

  /// The pressed state of [primary].
  Color get pressed => Color.lerp(primary, Colors.black, 0.2)!;

  /// Accent-coloured text and icons on the light surfaces (canvas, white,
  /// sunken, [tint]). Six of the seven [primary] values are under 4.5:1 there,
  /// so text uses the darker [pressed] shade.
  Color get text => pressed;

  /// A light wash of [primary] for selected rows and tonal buttons.
  Color get tint => Color.lerp(AppColors.surface, primary, 0.12)!;

  /// Text and icons on [primary].
  Color get onPrimary => Colors.white;
}
