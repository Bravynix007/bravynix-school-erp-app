import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_access_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';

class _MockAccessBloc extends MockBloc<StaffAccessEvent, StaffAccessState> implements StaffAccessBloc;

class _MockProfileBloc extends MockBloc<StaffProfileEvent, StaffProfileState> implements StaffProfileBloc;

const _lakeView = InstitutionSummary(id: 'i2', code: 'LVS', name: 'Lake View School');
const _hillTop = InstitutionSummary(id: 'i3', code: 'HTS', name: 'Hill Top School');

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockAccessBloc bloc;
  late _MockProfileBloc profile;

  setUpAll(() {
    registerFallbackValue(const StaffAccessStarted());
    registerFallbackValue(const StaffProfileRequested());
  });

  setUp(() {
    bloc = _MockAccessBloc();
    profile = _MockProfileBloc();
    when(() => bloc.canChangeInstitutions).thenReturn(true);
  });

  StaffAccessReady ready({
    List<String> subjectIds = const ['u1'],
    List<String> institutionIds = const ['i2'],
    StaffAccessPart? saving,
    ApiFailure? failure,
    StaffAccessPart? failedPart,
  }) => StaffAccessReady(
    member: kavyaWith(subjectIds: const ['u1'], institutionIds: const ['i2']),
    subjects: const [art, maths],
    institutions: const [_lakeView, _hillTop],
    subjectIds: subjectIds,
    institutionIds: institutionIds,
    saving: saving,
    failure: failure,
    failedPart: failedPart,
  );

  Future<void> pump(
    WidgetTester tester,
    StaffAccessState state, {
    bool owner = true,
    double textScale = 1,
    Size size = const Size(400, 1600),
    Widget? adminAccess,
  }) {
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.canChangeInstitutions).thenReturn(owner);
    return tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<StaffAccessBloc>.value(value: bloc),
          BlocProvider<StaffProfileBloc>.value(value: profile),
        ],
        child: Scaffold(body: StaffAccessView(adminAccess: adminAccess)),
      ),
      textScale: textScale,
      size: size,
    );
  }

  Finder tile(String key) => find.byKey(ValueKey(key));
  AppButton button(WidgetTester tester, String key) => tester.widget<AppButton>(find.byKey(Key(key)));
  bool ticked(WidgetTester tester, String key) => tester
      .widget<Semantics>(find.descendant(of: tile(key), matching: find.byType(Semantics)).first)
      .properties
      .checked!;

  group('the lists', () {
    testWidgets('show the subjects and the other Institutions, with what the person holds ticked', (tester) async {
      await pump(tester, ready());
      for (final text in [
        'Subjects they can teach',
        'Art',
        'Mathematics',
        'Other Institutions',
        'Lake View School',
        'Hill Top School',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(ticked(tester, 'staffAccess.subject.u1'), isTrue);
      expect(ticked(tester, 'staffAccess.subject.u2'), isFalse);
      expect(ticked(tester, 'staffAccess.institution.i2'), isTrue);
      expect(ticked(tester, 'staffAccess.institution.i3'), isFalse);
    });

    testWidgets('leave the Institutions to the Society Owner', (tester) async {
      await pump(tester, ready(), owner: false);
      expect(find.text('Subjects they can teach'), findsOneWidget);
      expect(find.text('Other Institutions'), findsNothing);
      expect(find.byKey(const Key('staffAccess.saveInstitutions')), findsNothing);
    });

    testWidgets('carry the Admin access part below them when there is one, and nothing else when there is not', (
      tester,
    ) async {
      await pump(tester, ready());
      expect(find.byKey(const Key('adminAccess')), findsNothing);
      await pump(tester, ready(), adminAccess: const SizedBox(key: Key('adminAccess'), height: 10));
      expect(find.byKey(const Key('adminAccess')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('adminAccess'))).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const Key('staffAccess.saveInstitutions'))).dy),
      );
    });

    testWidgets('say when there is nothing to choose from', (tester) async {
      await pump(
        tester,
        StaffAccessReady(
          member: kavyaWith(),
          subjects: const [],
          institutions: const [],
          subjectIds: const [],
          institutionIds: const [],
        ),
      );
      expect(find.byKey(const Key('staffAccess.subject.empty')), findsOneWidget);
      expect(find.text('No subjects yet. Add them under School setup, Subjects.'), findsOneWidget);
      expect(find.text('There is no other Institution in this Society.'), findsOneWidget);
    });

    testWidgets('keep a subject or an Institution ticked that is no longer offered, so it can be kept or taken off', (
      tester,
    ) async {
      await pump(tester, ready(subjectIds: const ['u1', 'gone'], institutionIds: const ['i2', 'closed']));
      expect(find.text('No longer offered (kept)'), findsNWidgets(2));
      expect(ticked(tester, 'staffAccess.subject.gone'), isTrue);
      await tester.tap(tile('staffAccess.subject.gone'));
      verify(() => bloc.add(const StaffSubjectToggled('gone'))).called(1);
      await tester.tap(tile('staffAccess.institution.closed'));
      verify(() => bloc.add(const StaffInstitutionToggled('closed'))).called(1);
    });

    testWidgets('tell the bloc what is ticked', (tester) async {
      await pump(tester, ready());
      await tester.tap(tile('staffAccess.subject.u2'));
      verify(() => bloc.add(const StaffSubjectToggled('u2'))).called(1);
      await tester.tap(tile('staffAccess.institution.i3'));
      verify(() => bloc.add(const StaffInstitutionToggled('i3'))).called(1);
    });

    testWidgets('offer no more to tick at 50, but still let one be taken off', (tester) async {
      final fifty = [for (var i = 0; i < maxStaffAccessChoices; i++) 'x$i'];
      await pump(tester, ready(subjectIds: fifty), size: const Size(400, 4000));
      await tester.tap(tile('staffAccess.subject.u1'));
      verifyNever(() => bloc.add(any(that: isA<StaffSubjectToggled>())));
      await tester.tap(tile('staffAccess.subject.x0'));
      verify(() => bloc.add(const StaffSubjectToggled('x0'))).called(1);
    });
  });

  group('saving', () {
    testWidgets('is not offered while nothing is changed', (tester) async {
      await pump(tester, ready());
      expect(button(tester, 'staffAccess.saveSubjects').onPressed, isNull);
      expect(button(tester, 'staffAccess.saveInstitutions').onPressed, isNull);
    });

    testWidgets('is offered for the subjects on their own, and sends that list', (tester) async {
      await pump(tester, ready(subjectIds: const ['u1', 'u2']));
      expect(button(tester, 'staffAccess.saveSubjects').onPressed, isNotNull);
      expect(button(tester, 'staffAccess.saveInstitutions').onPressed, isNull);
      await tester.tap(find.text('Save subjects'));
      verify(() => bloc.add(const StaffAccessSaved(StaffAccessPart.subjects))).called(1);
    });

    testWidgets('is offered for the Institutions on their own', (tester) async {
      await pump(tester, ready(institutionIds: const ['i2', 'i3']));
      expect(button(tester, 'staffAccess.saveSubjects').onPressed, isNull);
      await tester.tap(find.text('Save Institutions'));
      verify(() => bloc.add(const StaffAccessSaved(StaffAccessPart.institutions))).called(1);
    });

    testWidgets('shows the list that is on its way, and offers no other Save meanwhile', (tester) async {
      await pump(
        tester,
        ready(subjectIds: const ['u1', 'u2'], institutionIds: const ['i3'], saving: StaffAccessPart.subjects),
      );
      expect(button(tester, 'staffAccess.saveSubjects').loading, isTrue);
      expect(button(tester, 'staffAccess.saveInstitutions').loading, isFalse);
      expect(button(tester, 'staffAccess.saveInstitutions').onPressed, isNull);
    });

    testWidgets('offers no Save for the subjects while the Institutions are on their way', (tester) async {
      await pump(
        tester,
        ready(subjectIds: const ['u1', 'u2'], institutionIds: const ['i3'], saving: StaffAccessPart.institutions),
      );
      expect(button(tester, 'staffAccess.saveInstitutions').loading, isTrue);
      expect(button(tester, 'staffAccess.saveSubjects').loading, isFalse);
      expect(button(tester, 'staffAccess.saveSubjects').onPressed, isNull);
    });

    testWidgets('tells the profile behind of the staff member the API answered with, once a list is saved', (
      tester,
    ) async {
      final saved = ready(subjectIds: const ['u1', 'u2']);
      final next = StaffAccessReady(
        member: kavyaWith(subjectIds: const ['u1', 'u2'], institutionIds: const ['i2']),
        subjects: saved.subjects,
        institutions: saved.institutions,
        subjectIds: const ['u1', 'u2'],
        institutionIds: const ['i2'],
      );
      whenListen(bloc, Stream.value(next), initialState: saved);
      await tester.pumpAppScaled(
        MultiBlocProvider(
          providers: [
            BlocProvider<StaffAccessBloc>.value(value: bloc),
            BlocProvider<StaffProfileBloc>.value(value: profile),
          ],
          child: const Scaffold(body: StaffAccessView()),
        ),
        size: const Size(400, 1600),
      );
      await tester.pump();
      verify(() => profile.add(StaffProfileMemberChanged(next.member))).called(1);
      expect(find.text('Access saved'), findsOneWidget);
    });

    testWidgets('does not tell the profile of a change that is only ticking', (tester) async {
      whenListen(bloc, Stream.value(ready(subjectIds: const ['u1', 'u2'])), initialState: ready());
      await tester.pumpAppScaled(
        MultiBlocProvider(
          providers: [
            BlocProvider<StaffAccessBloc>.value(value: bloc),
            BlocProvider<StaffProfileBloc>.value(value: profile),
          ],
          child: const Scaffold(body: StaffAccessView()),
        ),
        size: const Size(400, 1600),
      );
      await tester.pump();
      verifyNever(() => profile.add(any()));
      expect(find.text('Access saved'), findsNothing);
    });
  });

  group('after a refused save', () {
    for (final (part, code, text) in [
      (
        StaffAccessPart.subjects,
        'SUBJECT_ASSIGNED',
        'They are assigned to teach one of the subjects you removed. End that assignment first.',
      ),
      (StaffAccessPart.subjects, 'REFERENCE_INACTIVE', 'Something you chose is no longer available. Choose again.'),
      (
        StaffAccessPart.institutions,
        'ADMIN_ACCESS_HELD',
        'They are an Institution Admin at one of the Institutions you removed. Take that Admin Access away first.',
      ),
      (StaffAccessPart.institutions, 'FORBIDDEN', "You don't have access to this."),
      (StaffAccessPart.subjects, 'NOT_FOUND', 'This staff member could not be found. They may have been deactivated.'),
    ]) {
      testWidgets('says $code under the list it was for, and under that list only', (tester) async {
        await pump(tester, ready(failure: _failure(409, code), failedPart: part));
        final here = part == StaffAccessPart.subjects ? 'staffAccess.subject.error' : 'staffAccess.institution.error';
        final other = part == StaffAccessPart.subjects ? 'staffAccess.institution.error' : 'staffAccess.subject.error';
        expect(find.descendant(of: find.byKey(Key(here)), matching: find.text(text)), findsOneWidget);
        expect(find.byKey(Key(other)), findsNothing);
      });
    }
  });

  group('before the lists are ready', () {
    testWidgets('shows a placeholder while they load', (tester) async {
      await pump(tester, const StaffAccessLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('says why they could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StaffAccessFailed(ApiFailure.network()));
      expect(find.byKey(const Key('staffAccess.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StaffAccessStarted())).called(1);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StaffAccessFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('staffAccess.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(
      tester,
      ready(failure: _failure(409, 'SUBJECT_ASSIGNED'), failedPart: StaffAccessPart.subjects),
      textScale: 2,
      size: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
    await tester.scrollUntilVisible(find.byKey(const Key('staffAccess.saveInstitutions')), 300);
    expect(tester.takeException(), isNull);
  });
}
