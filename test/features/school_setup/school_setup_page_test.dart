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
    expect(find.text('Academic years'), findsOneWidget);
    expect(find.text('Subjects'), findsOneWidget);
    expect(find.text('Classes'), findsOneWidget);
  });

  testWidgets('opens the Institutions', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.institutions, builder: (_, _) => const Text('institutions screen')),
        GoRoute(path: AppRoutes.academicYears, builder: (_, _) => const Text('academic years screen')),
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

  testWidgets('opens the Academic years', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.academicYears, builder: (_, _) => const Text('academic years screen')),
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
    await tester.tap(find.byKey(const Key('schoolSetup.academicYears')));
    await tester.pumpAndSettle();
    expect(find.text('academic years screen'), findsOneWidget);
  });

  testWidgets('opens the Subjects', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.subjects, builder: (_, _) => const Text('subjects screen')),
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
    await tester.tap(find.byKey(const Key('schoolSetup.subjects')));
    await tester.pumpAndSettle();
    expect(find.text('subjects screen'), findsOneWidget);
  });

  testWidgets('opens the Classes', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.classes, builder: (_, _) => const Text('classes screen')),
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
    await tester.tap(find.byKey(const Key('schoolSetup.classes')));
    await tester.pumpAndSettle();
    expect(find.text('classes screen'), findsOneWidget);
  });

  testWidgets('opens the Teachers / Staff', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.staff, builder: (_, _) => const Text('staff screen')),
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
    await tester.tap(find.byKey(const Key('schoolSetup.staff')));
    await tester.pumpAndSettle();
    expect(find.text('staff screen'), findsOneWidget);
  });

  testWidgets('opens the Students', (tester) async {
    // Tall enough to show the last tile without scrolling.
    tester.view
      ..physicalSize = const Size(800, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SchoolSetupPage()),
        GoRoute(path: AppRoutes.students, builder: (_, _) => const Text('students screen')),
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
    await tester.tap(find.byKey(const Key('schoolSetup.students')));
    await tester.pumpAndSettle();
    expect(find.text('students screen'), findsOneWidget);
  });

  testWidgets('is usable at a large text scale on a small phone', (tester) async {
    await tester.pumpAppScaled(const SchoolSetupPage(), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
