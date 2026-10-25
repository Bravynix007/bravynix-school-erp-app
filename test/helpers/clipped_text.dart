import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Text drawn shorter than its lines need (cut), on one line but wider than its
/// box, cut by maxLines, or with a word broken across lines. A word wider than
/// [unbreakable] cannot fit any box on the phone and is left out of the
/// mid-word check.
List<String> clippedParagraphs(WidgetTester tester, {Finder? within, double unbreakable = double.infinity}) {
  final clipped = <String>[];
  final texts = within == null ? find.byType(RichText) : find.descendant(of: within, matching: find.byType(RichText));
  for (final element in texts.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    if (!paragraph.hasSize) continue;
    final text = paragraph.text.toPlainText();
    if (paragraph.didExceedMaxLines) clipped.add('"$text" exceeds maxLines');
    final needed = paragraph.getDryLayout(BoxConstraints(maxWidth: paragraph.size.width)).height;
    if (needed > paragraph.size.height + 0.5) {
      clipped.add(
        '"$text" needs ${needed.toStringAsFixed(1)} px of height but has ${paragraph.size.height.toStringAsFixed(1)}',
      );
    }
    final noWrap = !paragraph.softWrap || paragraph.maxLines == 1;
    if (noWrap && paragraph.getMaxIntrinsicWidth(double.infinity) > paragraph.size.width + 0.5) {
      clipped.add('"$text" is wider than its box');
    }
    for (final word in text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty)) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      final wordWidth = painter.width;
      painter.dispose();
      if (wordWidth > paragraph.size.width + 0.5 && wordWidth <= unbreakable) {
        clipped.add(
          '"$word" in "$text" is broken mid-word (${wordWidth.toStringAsFixed(1)} in ${paragraph.size.width.toStringAsFixed(1)})',
        );
      }
    }
  }
  return clipped;
}
