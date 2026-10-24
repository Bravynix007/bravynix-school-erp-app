import 'package:flutter/material.dart';

/// The BravyNix palette, shared with the console's "Quiet Ledger" tokens
/// (design/super-admin-console/DESIGN.md 3) so both clients look like one
/// product. The mobile screens get their own Stitch pass per module; these
/// are the base.
abstract final class AppColors {
  static const canvas = Color(0xFFF6F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const sunken = Color(0xFFEFEDE7);

  static const ink = Color(0xFF16222C);
  static const inkSecondary = Color(0xFF56626C);
  static const inkTertiary = Color(0xFF646E77);

  static const primary = Color(0xFF0E5E5A);
  static const primaryPressed = Color(0xFF0B4B48);
  static const primaryTint = Color(0xFFE3EFEC);

  static const border = Color(0xFFE0DDD5);
  static const divider = Color(0xFFECE9E2);

  static const success = Color(0xFF1E7347);
  static const successBg = Color(0xFFE6F2EA);
  static const warning = Color(0xFF9A5407);
  static const warningBg = Color(0xFFFBEFDF);
  static const error = Color(0xFFB3261E);
  static const errorBg = Color(0xFFFBE9E8);
  static const info = Color(0xFF2B5A94);
  static const infoBg = Color(0xFFE7EEF7);

  static const disabled = Color(0xFF9AA3AA);
}
