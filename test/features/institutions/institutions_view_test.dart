import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institutions_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institutions_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/pump_app.dart';

class _MockInstitutionsBloc extends MockBloc<InstitutionsEvent, InstitutionsState> implements InstitutionsBloc;

void main() {
  late _MockInstitutionsBloc bloc;
  setUpAll(() => registerFallbackValue(const InstitutionsRequested()));
  setUp(() => bloc = _MockInstitutionsBloc());

  Future<void> pump(WidgetTester tester, InstitutionsState state, {double textScale = 1, bool canAdd = false}) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<InstitutionsBloc>.value(
        value: bloc,
        child: InstitutionsView(canAdd: canAdd),
      ),
      textScale: textScale,
    );
  }

  testWidgets('lists each Institution with its code, place and board', (tester) async {
    await pump(
      tester,
      InstitutionsLoaded([
        summary(),
        summary(id: 'i2', code: 'LVS', name: 'Lake View School', place: null, board: null),
      ]),
    );
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.text('SVHS'), findsOneWidget);
    expect(find.text('Whitefield · CBSE'), findsOneWidget);
    expect(find.text('Lake View School'), findsOneWidget);
    expect(find.text('LVS'), findsOneWidget);
  });

  testWidgets('says there is nothing yet when the caller has no Institution', (tester) async {
    await pump(tester, const InstitutionsLoaded([]));
    expect(find.text('No Institutions yet'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const InstitutionsLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const InstitutionsFailed(ApiFailure.network()));
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const InstitutionsRequested())).called(1);
  });

  testWidgets('says a role that may not see Institutions has no access', (tester) async {
    await pump(tester, const InstitutionsFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.text("You don't have access to this."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('opens an Institution from its card, and reads the list again when it comes back changed', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(InstitutionsLoaded([summary()]));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              BlocProvider<InstitutionsBloc>.value(value: bloc, child: const InstitutionsView(canAdd: false)),
        ),
        GoRoute(
          path: AppRoutes.institutionPattern,
          builder: (context, state) => TextButton(
            onPressed: () => context.pop(true),
            child: Text('institution ${state.pathParameters['id']}'),
          ),
        ),
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
    await tester.tap(find.byKey(const ValueKey('institution.i1')));
    await tester.pumpAndSettle();
    expect(find.text('institution i1'), findsOneWidget);
    verifyNever(() => bloc.add(const InstitutionsRequested()));
    await tester.tap(find.text('institution i1'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InstitutionsRequested())).called(1);
  });

  group('adding', () {
    Future<void> pumpWithForm(WidgetTester tester, InstitutionsState state, {required bool saved}) async {
      when(() => bloc.state).thenReturn(state);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                BlocProvider<InstitutionsBloc>.value(value: bloc, child: const InstitutionsView(canAdd: true)),
          ),
          GoRoute(
            path: AppRoutes.institutionNew,
            builder: (context, _) => TextButton(onPressed: () => context.pop(saved), child: const Text('form')),
          ),
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
    }

    testWidgets('offers Add Institution to an Owner only', (tester) async {
      await pump(tester, InstitutionsLoaded([summary()]), canAdd: true);
      expect(find.byKey(const Key('institutions.add')), findsOneWidget);
      await pump(tester, InstitutionsLoaded([summary()]));
      expect(find.byKey(const Key('institutions.add')), findsNothing);
    });

    testWidgets('offers it in the empty list too, to an Owner only', (tester) async {
      await pump(tester, const InstitutionsLoaded([]), canAdd: true);
      expect(find.widgetWithText(FilledButton, 'Add Institution'), findsOneWidget);
    });

    testWidgets('does not offer it in the empty list to anyone else', (tester) async {
      await pump(tester, const InstitutionsLoaded([]));
      expect(find.text('Add Institution'), findsNothing);
    });

    testWidgets('reads the list again when the form saved', (tester) async {
      await pumpWithForm(tester, InstitutionsLoaded([summary()]), saved: true);
      await tester.tap(find.byKey(const Key('institutions.add')));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const InstitutionsRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const InstitutionsRequested())).called(1);
    });

    testWidgets('leaves the list as it is when the form was cancelled', (tester) async {
      await pumpWithForm(tester, InstitutionsLoaded([summary()]), saved: false);
      await tester.tap(find.byKey(const Key('institutions.add')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const InstitutionsRequested()));
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      InstitutionsLoaded([
        summary(name: 'Sri Vidya Educational Society Senior Secondary School', place: 'Whitefield, Bengaluru'),
        summary(id: 'i2', board: null),
      ]),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
