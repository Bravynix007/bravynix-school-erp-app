import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_bulk_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/view/class_bulk_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockBulkBloc extends MockBloc<ClassBulkEvent, ClassBulkState> implements ClassBulkBloc;

const _open = ClassBulkEditing(choices: [class1Choice, class2Choice]);

void main() {
  late _MockBulkBloc bloc;
  setUpAll(() => registerFallbackValue(const ClassBulkStarted()));
  setUp(() => bloc = _MockBulkBloc());

  Future<void> pump(
    WidgetTester tester,
    ClassBulkState state, {
    Set<String> added = const {},
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<ClassBulkBloc>.value(
        value: bloc,
        child: ClassBulkView(added: added),
      ),
      textScale: textScale,
      size: size,
    );
  }

  FilledButton save(WidgetTester tester) => tester.widget<FilledButton>(
    find.descendant(of: find.byType(StickyBottomActions), matching: find.byType(FilledButton)),
  );

  testWidgets('lists the classes under their categories, with nothing ticked and nothing to save yet', (tester) async {
    await pump(tester, _open);
    expect(find.text('Add several classes'), findsOneWidget);
    expect(find.text('Lower Primary'), findsOneWidget);
    expect(find.text('Class 1'), findsOneWidget);
    expect(find.text('Class 2'), findsOneWidget);
    expect(find.text('Add classes'), findsOneWidget);
    expect(save(tester).onPressed, isNull);
  });

  testWidgets('Add sends the classes ticked, in the order the list shows them, and counts them', (tester) async {
    await pump(tester, _open);
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p2')));
    await tester.pump();
    expect(find.text('Add 1 class'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p1')));
    await tester.pump();
    expect(find.text('Add 2 classes'), findsOneWidget);
    await tester.tap(find.text('Add 2 classes'));
    verify(() => bloc.add(const ClassBulkSubmitted(['p1', 'p2']))).called(1);
  });

  testWidgets('ticking a class again unticks it', (tester) async {
    await pump(tester, _open);
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p1')));
    await tester.pump();
    expect(find.text('Add classes'), findsOneWidget);
    expect(save(tester).onPressed, isNull);
  });

  testWidgets('a class already added is marked and cannot be ticked', (tester) async {
    await pump(tester, _open, added: {'p1'});
    expect(find.text('Already added'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p1')));
    await tester.pump();
    expect(find.text('Add classes'), findsOneWidget);
    expect(find.byKey(const Key('classBulk.none')), findsNothing);
  });

  testWidgets('says when every class is already added', (tester) async {
    await pump(tester, _open, added: {'p1', 'p2'});
    expect(find.byKey(const Key('classBulk.none')), findsOneWidget);
  });

  testWidgets('while saving, Add does nothing', (tester) async {
    await pump(tester, const ClassBulkEditing(choices: [class1Choice], saving: true));
    expect(save(tester).onPressed, isNull);
  });

  testWidgets('says why the add was refused, naming nothing it cannot show', (tester) async {
    await pump(
      tester,
      const ClassBulkEditing(
        choices: [class1Choice],
        failure: ApiFailure(
          statusCode: 409,
          code: 'DUPLICATE',
          message: 'x',
          fieldErrors: [FieldError(field: 'classes[1].predefinedClassId', code: 'DUPLICATE', message: 'x')],
        ),
      ),
    );
    expect(find.byKey(const Key('classBulk.error')), findsOneWidget);
    expect(find.text('Another class of this Institution already has this name or stream.'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const ClassBulkLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and reads again on Try again', (tester) async {
    await pump(tester, const ClassBulkFailed(ApiFailure.network()));
    expect(find.byKey(const Key('classBulk.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ClassBulkStarted())).called(1);
  });

  testWidgets('closes with true and says how many were added', (tester) async {
    whenListen(
      bloc,
      Stream.value(const ClassBulkSaved([class1, pucClass])),
      initialState: const ClassBulkEditing(choices: [class1Choice], saving: true),
    );
    bool? closedWith;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => closedWith = await context.push<bool>('/bulk'),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: '/bulk',
          builder: (_, _) => BlocProvider<ClassBulkBloc>.value(
            value: bloc,
            child: const ClassBulkView(added: {}),
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(closedWith, isTrue);
    expect(find.text('2 classes added'), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, _open, added: {'p1'}, textScale: 2, size: const Size(320, 2400));
    await tester.tap(find.byKey(const ValueKey('classBulk.choice.p2')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
