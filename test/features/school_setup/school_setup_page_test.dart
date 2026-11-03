import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/school_setup/presentation/school_setup_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('lists the setup screens that exist', (tester) async {
    await tester.pumpApp(const SchoolSetupPage());
    expect(find.text('School setup'), findsOneWidget);
    expect(find.text('Institutions'), findsOneWidget);
  });

  testWidgets('opens the Institutions', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.institutions, builder: (_, _) => const Text('institutions screen')),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.tap(find.byKey(const Key('schoolSetup.institutions')));
    await tester.pumpAndSettle();
    expect(find.text('institutions screen'), findsOneWidget);
  });

  testWidgets('is usable at a large text scale on a small phone', (tester) async {
    await tester.pumpAppScaled(const SchoolSetupPage(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
