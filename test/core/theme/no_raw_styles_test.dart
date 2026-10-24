import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colours, font sizes and text styles are written in lib/core/theme only; a
/// screen asks the theme for them. This keeps every screen on the tokens, so a
/// change to a token reaches all of them.
void main() {
  test('no raw colours or font sizes outside the theme folder', () {
    final raw = RegExp(
      r'Color\(0[xX]|Color\.from(ARGB|RGBO)|(?<![A-Za-z])Colors\.(?!transparent|white|black\b)\w|CupertinoColors\.'
      r'|Colors\.(black|white)(\d+|Accent)|fontSize:|letterSpacing:|(?<![A-Za-z_])TextStyle\(',
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || path.startsWith('lib/core/theme/') || path.startsWith('lib/l10n/gen/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i += 1) {
        if (raw.hasMatch(lines[i]) && !lines[i].contains('// token-ok')) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Use AppColors, AppTextStyles or the theme (or mark the line // token-ok).');
  });
}
