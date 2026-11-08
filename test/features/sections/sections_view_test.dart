import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/theme/app_theme.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/sections_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_form_page.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/sections_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/sections.dart';

class _MockSectionsBloc extends MockBloc<ListEvent, ListState<Section>> implements SectionsBloc;

void main() {
  late _MockSectionsBloc bloc;
  setUpAll(() {
    registerFallbackValue(const ListRequested());
    registerFallbackValue(const SectionDeactivated(sectionA));
  });
  setUp(() => bloc = _MockSectionsBloc());

  Future<void> pump(
    WidgetTester tester,
    ListState<Section> state, {
    double textScale = 1,
    Size size = const Size(400, 1200),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<SectionsBloc>.value(
        value: bloc,
        child: const SectionsView(schoolClass: class1),
      ),
      textScale: textScale,
      size: size,
    );
  }

  /// The list on a router whose form answers [saved] when it closes, recording what it was given.
  Future<List<Object?>> pumpWithForm(WidgetTester tester, ListState<Section> state, {required bool saved}) async {
    when(() => bloc.state).thenReturn(state);
    final opened = <Object?>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BlocProvider<SectionsBloc>.value(
              value: bloc,
              child: const SectionsView(schoolClass: class1),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.sectionForm,
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

  testWidgets('names the class and lists each section with its capacity and a dash for students', (tester) async {
    await pump(tester, const ListLoaded<Section>([sectionA, sectionB]));
    expect(find.text('Class 1'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);
    expect(find.text('Capacity 40 · Students —'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    // A section renamed shows the predefined section it is, and says when no capacity is set.
    expect(find.text('Section B · No capacity set · Students —'), findsOneWidget);
  });

  testWidgets('shows the student count once the People module sends it', (tester) async {
    const placed = Section(
      id: 'e3',
      classId: 'k1',
      predefinedSection: sectionARef,
      displayName: 'Section A',
      version: 1,
      currentStudentCount: 31,
    );
    await pump(tester, const ListLoaded<Section>([placed]));
    expect(find.text('No capacity set · Students 31'), findsOneWidget);
  });

  testWidgets('Deactivate asks first, and does nothing when cancelled', (tester) async {
    await pump(tester, const ListLoaded<Section>([sectionA]));
    await tester.tap(find.byKey(const ValueKey('section.deactivate.e1')));
    await tester.pumpAndSettle();
    expect(find.text('Deactivate Section A?'), findsOneWidget);
    expect(find.text('Its name can be used again. Nothing is deleted.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(any(that: isA<SectionDeactivated>())));
  });

  testWidgets('Deactivate goes ahead once confirmed', (tester) async {
    await pump(tester, const ListLoaded<Section>([sectionA]));
    await tester.tap(find.byKey(const ValueKey('section.deactivate.e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Deactivate')));
    await tester.pumpAndSettle();
    verify(() => bloc.add(const SectionDeactivated(sectionA))).called(1);
  });

  testWidgets('while a deactivation is on its way, no card starts another change', (tester) async {
    await pump(tester, const ListLoaded<Section>([sectionA, sectionB], busyId: 'e1'));
    Finder button(String key) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    expect(tester.widget<ButtonStyleButton>(button('section.edit.e1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('section.deactivate.e1')).onPressed, isNull);
    expect(tester.widget<ButtonStyleButton>(button('section.edit.e2')).onPressed, isNull);
  });

  testWidgets('says why a deactivation was refused, above the list', (tester) async {
    await pump(
      tester,
      const ListLoaded<Section>(
        [sectionA],
        actionFailure: ApiFailure(statusCode: 409, code: 'HAS_STUDENTS', message: 'x'),
      ),
    );
    expect(find.byKey(const Key('sections.actionFailed')), findsOneWidget);
    expect(find.text('Students are placed in this section. Move them first.'), findsOneWidget);
  });

  testWidgets('says which section was deactivated', (tester) async {
    whenListen(
      bloc,
      Stream.value(const ListLoaded<Section>([sectionB], changed: sectionA)),
      initialState: const ListLoaded<Section>([sectionA, sectionB]),
    );
    await tester.pumpAppScaled(
      Scaffold(
        body: BlocProvider<SectionsBloc>.value(
          value: bloc,
          child: const SectionsView(schoolClass: class1),
        ),
      ),
      size: const Size(400, 1200),
    );
    await tester.pump();
    expect(find.text('Section A deactivated'), findsOneWidget);
  });

  testWidgets('invites the first section when there is none', (tester) async {
    await pump(tester, const ListLoaded<Section>([]));
    expect(find.text('No sections yet'), findsOneWidget);
    expect(find.text('Add the sections of Class 1, such as A and B.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add section'), findsOneWidget);
  });

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const ListLoading<Section>());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const ListFailed<Section>(ApiFailure.network()));
    expect(find.byKey(const Key('sections.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const ListRequested())).called(1);
  });

  testWidgets('a class deactivated meanwhile is said to be gone, not a section', (tester) async {
    await pump(tester, const ListFailed<Section>(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
    expect(find.text('This class could not be found. It may have been deactivated.'), findsOneWidget);
    expect(find.text('This section could not be found. It may have been deactivated.'), findsNothing);
  });

  testWidgets('says a role that may not see sections has no access', (tester) async {
    await pump(tester, const ListFailed<Section>(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('sections.forbidden')), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  group('the form', () {
    testWidgets('Add section hands over the class and the sections it has, and reads again once saved', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<Section>([sectionA, sectionB]), saved: true);
      await tester.tap(find.byKey(const Key('sections.add')));
      await tester.pumpAndSettle();
      final args = opened.single! as SectionFormArgs;
      expect(args.classId, 'k1');
      expect(args.taken, {'s1', 's2'});
      expect(args.section, isNull);
      verifyNever(() => bloc.add(const ListRequested()));
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const ListRequested())).called(1);
    });

    testWidgets('the empty list opens it too', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<Section>([]), saved: false);
      await tester.tap(find.widgetWithText(FilledButton, 'Add section'));
      await tester.pumpAndSettle();
      expect((opened.single! as SectionFormArgs).taken, isEmpty);
    });

    testWidgets('Edit hands the section over, and leaves the list alone when the form was cancelled', (tester) async {
      final opened = await pumpWithForm(tester, const ListLoaded<Section>([sectionA, sectionB]), saved: false);
      await tester.tap(find.byKey(const ValueKey('section.edit.e2')));
      await tester.pumpAndSettle();
      expect((opened.single! as SectionFormArgs).section, sectionB);
      await tester.tap(find.text('form'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(const ListRequested()));
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const ListLoaded<Section>([sectionA, sectionB]), textScale: 2, size: const Size(320, 1800));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
