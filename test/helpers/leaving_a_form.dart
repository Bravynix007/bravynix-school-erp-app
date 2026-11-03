import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Every way out of a form opened from a list: Cancel, the arrow in the top bar and the system back. After a save
/// refused because the list holds an old copy (VERSION_CONFLICT, NOT_FOUND) each closes with `true`, so the list reads
/// again; after any other refusal, or none, none does. [setFailure] puts the form in the state of a refusal (null: none);
/// [backToList] is the button the banner of a version conflict offers, which does the same. [closing] and [staying] are
/// the refusals after which leaving closes with `true` or not.
void leavingAFormTests({
  required void Function(ApiFailure? failure) setFailure,
  required Widget Function() form,
  Key? backToList,
  List<(int, String)> closing = const [(409, 'VERSION_CONFLICT'), (404, 'NOT_FOUND')],
  List<(int, String)> staying = const [(409, 'DUPLICATE')],
}) {
  group('leaving the form', () {
    Future<bool?> leave(WidgetTester tester, ApiFailure? failure, Future<void> Function() exit) async {
      setFailure(failure);
      bool? closedWith;
      var closed = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  closedWith = await context.push<bool>('/form');
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(path: '/form', builder: (_, _) => form()),
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
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await exit();
      await tester.pumpAndSettle();
      expect(closed, isTrue, reason: 'the form closed');
      return closedWith;
    }

    if (backToList != null) {
      testWidgets('Back to the list after VERSION_CONFLICT closes with true, so the list reads again', (tester) async {
        final closedWith = await leave(
          tester,
          const ApiFailure(statusCode: 409, code: 'VERSION_CONFLICT', message: 'x'),
          () => tester.tap(find.byKey(backToList)),
        );
        expect(closedWith, isTrue);
      });
    }

    final exits = <String, Future<void> Function(WidgetTester)>{
      'Cancel': (tester) => tester.tap(find.text('Cancel')),
      'the arrow in the top bar': (tester) => tester.tap(find.byTooltip('Back')),
      'the system back': (tester) => tester.binding.handlePopRoute(),
    };
    for (final MapEntry(key: name, value: exit) in exits.entries) {
      for (final (status, code) in closing) {
        testWidgets('$name after $code closes with true, so the list reads again', (tester) async {
          final closedWith = await leave(
            tester,
            ApiFailure(statusCode: status, code: code, message: 'x'),
            () => exit(tester),
          );
          expect(closedWith, isTrue);
        });
      }
      for (final (status, code) in staying) {
        testWidgets('$name after $code leaves the list alone', (tester) async {
          final closedWith = await leave(
            tester,
            ApiFailure(statusCode: status, code: code, message: 'x'),
            () => exit(tester),
          );
          expect(closedWith, isNot(true));
        });
      }
      testWidgets('$name with nothing refused leaves the list alone', (tester) async {
        expect(await leave(tester, null, () => exit(tester)), isNot(true));
      });
    }
  });
}
