import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_week.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/timetable_bloc.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/entry_form_page.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/view/timetable_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/timetable.dart';

class _MockTimetableBloc extends MockBloc<ListEvent, ListState<TimetableEntry>> implements TimetableBloc;

void main() {
  late _MockTimetableBloc bloc;
  setUpAll(() {
    registerFallbackValue(const ListRequested());
    registerFallbackValue(const EntryRemoved(mathsMonday));
  });
  setUp(() => bloc = _MockTimetableBloc());

  final monday = DateTime(2026, 11, 16);

  Widget view({String? institutionId = 'i1', TimetableWeek week = const SectionWeek('sec1')}) => Scaffold(
    body: BlocProvider<TimetableBloc>.value(
      value: bloc,
      child: TimetableView(week: week, today: monday, institutionId: institutionId),
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    ListState<TimetableEntry> state, {
    String? institutionId = 'i1',
    TimetableWeek week = const SectionWeek('sec1'),
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      view(institutionId: institutionId, week: week),
      textScale: textScale,
      size: size,
    );
  }

  /// The week on a router whose form answers [saved] when it closes, recording what it was given.
  Future<List<Object?>> pumpWithForm(
    WidgetTester tester,
    ListState<TimetableEntry> state, {
    required bool saved,
  }) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => view()),
        GoRoute(
          path: AppRoutes.timetableEntryForm,
          builder: (context, routeState) {
            opened.add(routeState.extra);
            return TextButton(onPressed: () => context.pop(saved), child: const Text('form'));
          },
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
    return opened;
  }

  const week = ListLoaded<TimetableEntry>([mathsMonday, lunchMonday]);

  testWidgets('offers Add entry, Edit and Delete only on a section week the person builds', (tester) async {
    await pump(tester, week);
    expect(find.byKey(const Key('timetable.add')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable.edit.x1')), findsOneWidget);
    expect(find.byKey(const ValueKey('timetable.delete.x2')), findsOneWidget);
    // A teacher's own week and a parent's child's are read only.
    await pump(tester, week, institutionId: null);
    expect(find.byKey(const Key('timetable.add')), findsNothing);
    expect(find.byKey(const ValueKey('timetable.edit.x1')), findsNothing);
  });

  testWidgets('offers it nowhere on a week that is not a section’s, even with an Institution', (tester) async {
    await pump(tester, week, week: const OwnWeek('i1'));
    expect(find.byKey(const Key('timetable.add')), findsNothing);
    expect(find.byKey(const ValueKey('timetable.delete.x1')), findsNothing);
  });

  testWidgets('an empty week invites the first entry', (tester) async {
    await pump(tester, const ListLoaded<TimetableEntry>([]));
    expect(find.widgetWithText(FilledButton, 'Add entry'), findsOneWidget);
    await pump(tester, const ListLoaded<TimetableEntry>([]), institutionId: null);
    expect(find.text('Add entry'), findsNothing);
  });

  group('the form', () {
    testWidgets('Add entry hands over the section and the Institution, and reads again once saved', (tester) async {
      final opened = await pumpWithForm(tester, week, saved: true);
      await tester.tap(find.byKey(const Key('timetable.add')));
      await tester.pumpAndSettle();
      final args = opened.single! as EntryFormArgs;
      expect(args.sectionId, 'sec1');
      expect(args.institutionId, 'i1');
      expect(args.entry, isNull);
      verifyNever(() => bloc.add(const ListRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });

    testWidgets('the empty week opens it too', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<TimetableEntry>([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add entry'));
      await tester.pumpAndSettle();
      expect((opened.single! as EntryFormArgs).entry, isNull);
    });

    testWidgets('Edit hands the entry over, and leaves the week alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForm(tester, week, saved: false);
      await tester.tap(find.byKey(const ValueKey('timetable.edit.x1')));
      await tester.pumpAndSettle();
      expect((opened.single! as EntryFormArgs).entry, mathsMonday);
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const ListRequested()));
    });
  });

  group('Delete', () {
    testWidgets('asks first, and does nothing when cancelled', (tester) async {
      await pump(tester, week);
      await tester.tap(find.byKey(const ValueKey('timetable.delete.x1')));
      await tester.pumpAndSettle();
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('goes ahead once confirmed', (tester) async {
      await pump(tester, week);
      await tester.tap(find.byKey(const ValueKey('timetable.delete.x1')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Delete')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const EntryRemoved(mathsMonday))).called(1);
    });

    testWidgets('while one is on its way, no tile starts another change', (tester) async {
      await pump(tester, const ListLoaded<TimetableEntry>([mathsMonday, lunchMonday], busyId: 'x1'));
      Finder button(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(tester.widget<ButtonStyleButton>(button('timetable.edit.x1')).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(button('timetable.delete.x1')).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(button('timetable.edit.x2')).onPressed, isNull);
      expect(tester.widget<ButtonStyleButton>(button('timetable.delete.x2')).onPressed, isNull);
    });

    testWidgets('says why a deletion was refused, above the week', (tester) async {
      await pump(
        tester,
        const ListLoaded<TimetableEntry>(
          [mathsMonday],
          actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
        ),
      );
      expect(find.byKey(const Key('timetable.actionFailed')), findsOneWidget);
      expect(find.text('This timetable could not be found.'), findsOneWidget);
    });

    testWidgets('says the entry was deleted', (tester) async {
      whenListen(
        bloc,
        Stream.value(const ListLoaded<TimetableEntry>([lunchMonday], changed: mathsMonday)),
        initialState: week,
      );
      await tester.pumpAppScaled(view(), size: const Size(400, 1400));
      await tester.pump();
      expect(find.text('Entry deleted'), findsOneWidget);
    });
  });

  testWidgets('reads whole with its buttons at 320 px wide and twice the text size', (tester) async {
    await pump(tester, week, textScale: 2, size: const Size(320, 3200));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
  });
}
