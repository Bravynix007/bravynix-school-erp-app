import 'package:flutter/painting.dart';

/// WCAG contrast ratio of two opaque colours.
double contrast(Color a, Color b) {
  final lighter = a.computeLuminance() > b.computeLuminance() ? a : b;
  final darker = identical(lighter, a) ? b : a;
  return (lighter.computeLuminance() + 0.05) / (darker.computeLuminance() + 0.05);
}
