import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] with the app's theme and localisations.
  Future<void> pumpApp(Widget widget) => pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget,
    ),
  );

  /// Like [pumpApp] on a phone of [size] with the text scaled by [textScale].
  /// The scale is applied above the navigator, so sheets and dialogs opened
  /// from [widget] are scaled too.
  Future<void> pumpAppScaled(
    Widget widget, {
    double textScale = 1,
    Size size = const Size(320, 640),
    double bottomPadding = 0,
  }) {
    view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: EdgeInsets.only(bottom: bottomPadding),
            viewPadding: EdgeInsets.only(bottom: bottomPadding),
          ),
          child: child!,
        ),
        home: widget,
      ),
    );
  }

  /// The rendered height of the first [Text] showing [text], in logical pixels.
  double textHeight(String text) => getSize(find.text(text).first).height;
}
