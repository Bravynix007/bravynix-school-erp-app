import 'package:flutter/painting.dart';

/// Elevation is shown with soft shadows, not Material tint.
abstract final class AppShadows {
  static const card = [BoxShadow(color: Color(0x0F16222C), blurRadius: 8, offset: Offset(0, 2))];
  static const sheet = [BoxShadow(color: Color(0x2916222C), blurRadius: 24, offset: Offset(0, -4))];

  /// The bar pinned at the bottom of a form: a light shadow cast upward.
  static const stickyBar = [BoxShadow(color: Color(0x0F16222C), blurRadius: 8, offset: Offset(0, -2))];
  static const floatingNav = [BoxShadow(color: Color(0x2916222C), blurRadius: 20, offset: Offset(0, 6))];
}
