import 'package:flutter/material.dart';

/// How wide [text] is drawn in [style] at the phone's current text size. Used
/// by widgets that choose a layout from what fits, in any script.
double measureText(BuildContext context, String text, TextStyle? style, {TextScaler? scaler}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    locale: Localizations.maybeLocaleOf(context),
    textScaler: scaler ?? MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

/// The widest single word in [text]: the least width it can be drawn in
/// without breaking a word in half.
double longestWordWidth(BuildContext context, String text, TextStyle? style, {TextScaler? scaler}) {
  var widest = 0.0;
  for (final word in text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty)) {
    final width = measureText(context, word, style, scaler: scaler);
    if (width > widest) widest = width;
  }
  return widest;
}

/// How tall [text] is drawn in [style] when it wraps within [maxWidth], at the
/// phone's current text size. Used where a fixed box would cut a wrapped line.
double measureTextHeight(BuildContext context, String text, TextStyle? style, double maxWidth, {TextScaler? scaler}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    locale: Localizations.maybeLocaleOf(context),
    textScaler: scaler ?? MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);
  final height = painter.height;
  painter.dispose();
  return height;
}

/// The phone's own text scaler, unless the longest word of [text] would not
/// fit in [maxWidth] even on a line of its own. Then the largest scale at
/// which it does fit, so a word is never broken in half. A last resort for
/// bars and headers, after the layout has already given the text a full line.
TextScaler fitWordScaler(BuildContext context, String text, TextStyle? style, double maxWidth) {
  final scaler = MediaQuery.textScalerOf(context);
  final widest = longestWordWidth(context, text, style);
  if (widest <= maxWidth || widest == 0) return scaler;
  final fontSize = style?.fontSize ?? 14;
  // Width does not scale exactly with the factor (letter spacing, rounded glyph advances), so check
  // the result and step down until the word really fits.
  var factor = scaler.scale(fontSize) / fontSize * (maxWidth / widest) * 0.98;
  for (var i = 0; i < 6; i++) {
    final candidate = TextScaler.linear(factor);
    if (longestWordWidth(context, text, style, scaler: candidate) <= maxWidth) return candidate;
    factor *= 0.96;
  }
  return TextScaler.linear(factor);
}
