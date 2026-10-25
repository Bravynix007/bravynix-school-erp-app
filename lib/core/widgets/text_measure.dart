import 'package:flutter/material.dart';

/// How wide [text] is drawn in [style] at the phone's current text size. Used
/// by widgets that choose a layout from what fits, in any script.
double measureText(BuildContext context, String text, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The widest single word in [text]: the least width it can be drawn in
/// without breaking a word in half.
double longestWordWidth(BuildContext context, String text, TextStyle? style) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty)) {
    final width = measureText(context, word, style);
    if (width > widest) widest = width;
  }
  return widest;
}
