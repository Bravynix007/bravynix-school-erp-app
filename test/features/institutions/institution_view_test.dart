import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_bloc.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/pump_app.dart';

class _MockInstitutionBloc extends MockBloc<InstitutionEvent, InstitutionState> implements InstitutionBloc;

void main() {
  late _MockInstitutionBloc bloc;
  setUpAll(() => registerFallbackValue(const InstitutionRequested()));
  setUp(() => bloc = _MockInstitutionBloc());

  Future<void> pump(
    WidgetTester tester,
    InstitutionState state, {
    bool canDeactivate = true,
    double textScale = 1,
    Size size = const Size(320, 640),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<InstitutionBloc>.value(
        value: bloc,
        child: InstitutionView(canDeactivate: canDeactivate),
      ),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('shows the Institution, its contact, address and the categories it offers', (tester) async {
    await pump(tester, const InstitutionLoaded(institution), size: const Size(400, 1400));
    expect(find.text('Sri Vidya High School'), findsOneWidget);
    expect(find.text('SVHS'), findsOneWidget);
    expect(find.text('Whitefield'), findsOneWidget);
    expect(find.text('CBSE'), findsOneWidget);
    expect(find.text('830123'), findsOneWidget);
    expect(find.text('29ABCDE1234F1Z5'), findsOneWidget);
    expect(find.text('12 Lake Road\nNear the park\n560066'), findsOneWidget);
    expect(find.text('office@svhs.example.org'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.text('080 2345 6789'), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('Higher Primary'), findsOneWidget);
  });

  testWidgets('leaves out what is not set, and says when no category is offered', (tester) async {
    await pump(tester, const InstitutionLoaded(bareInstitution));
    expect(find.text('Place'), findsNothing);
    expect(find.text('Board'), findsNothing);
    expect(find.text('Affiliation number'), findsNothing);
    expect(find.text('GSTIN'), findsNothing);
    expect(find.text('Phone'), findsNothing);
    expect(find.text('3 Hill Street'), findsOneWidget);
    expect(find.text('No class categories are offered yet.'), findsOneWidget);
  });

  testWidgets('offers Deactivate to an Owner only', (tester) async {
    await pump(tester, const InstitutionLoaded(institution));
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    expect(find.byKey(const Key('institution.deactivate')), findsOneWidget);
    await pump(tester, const InstitutionLoaded(institution), canDeactivate: false);
    expect(find.byKey(const Key('institution.deactivate')), findsNothing);
  });

  testWidgets('asks before deactivating, and does nothing on Cancel', (tester) async {
    await pump(tester, const InstitutionLoaded(institution));
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    await tester.tap(find.byKey(const Key('institution.deactivate')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Sri Vidya High School?'), findsOneWidget);
    expect(find.textContaining('Nothing is deleted'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(const InstitutionDeactivateRequested()));
  });

  testWidgets('deactivates once confirmed', (tester) async {
    await pump(tester, const InstitutionLoaded(institution));
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    await tester.tap(find.byKey(const Key('institution.deactivate')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate Institution'));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const InstitutionDeactivateRequested())).called(1);
  });

  testWidgets('shows progress on the button while it deactivates', (tester) async {
    await pump(tester, const InstitutionLoaded(institution, deactivating: true));
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('says why a deactivation failed, in words beside the button', (tester) async {
    await pump(tester, const InstitutionLoaded(institution, deactivateFailure: ApiFailure.network()));
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    expect(find.byKey(const Key('institution.deactivateFailed')), findsOneWidget);
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
  });

  testWidgets('closes with a message and tells the list when it was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.value(const InstitutionDeactivated()),
      initialState: const InstitutionLoaded(institution),
    );
    bool? result;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await context.push<bool>('/institution'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/institution',
          builder: (_, _) =>
              BlocProvider<InstitutionBloc>.value(value: bloc, child: const InstitutionView(canDeactivate: true)),
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Institution deactivated'), findsOneWidget);
  });

  testWidgets('says the Institution could not be found, with no retry', (tester) async {
    await pump(tester, const InstitutionFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
    expect(find.text('This Institution could not be found. It may have been deactivated.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says there is no access', (tester) async {
    await pump(tester, const InstitutionFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.text("You don't have access to this."), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('tells a staff role whose Institution is blocked why', (tester) async {
    await pump(
      tester,
      const InstitutionFailed(
        ApiFailure(statusCode: 423, code: 'SECTION_BLOCKED', message: 'x', details: {'section': 'staff'}),
      ),
    );
    expect(find.text('Access is blocked for your group. Contact your Society.'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const InstitutionLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('loads again on Try again after a failure', (tester) async {
    await pump(tester, const InstitutionFailed(ApiFailure.network()));
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const InstitutionRequested())).called(1);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const InstitutionLoaded(institution), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    await tester.scrollUntilVisible(find.byKey(const Key('institution.deactivate')), 100);
    expect(tester.takeException(), isNull);
  });
}
