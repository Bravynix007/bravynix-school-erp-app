import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/day_picker.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_repository.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_form_bloc.dart';
import 'package:bravynix_school_erp/features/diary/presentation/view/diary_page.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_day_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/view/section_day_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/clipped_text.dart';
import '../../helpers/diary.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/subjects.dart';

ApiFailure refusal(String code, {int status = 422}) =>
    ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late MockDiaryRepository diary;
  late Future<SectionChoices> Function() load;
  setUpAll(() {
    registerFallbackValue(const DiaryInput(subjectId: '', day: '', description: ''));
    registerFallbackValue(mathsEntry);
  });
  setUp(() {
    diary = MockDiaryRepository();
    load = () async => oneSection.choices;
    when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry, artEntry, noticeEntry]);
    when(() => diary.subjects('sec1')).thenAnswer((_) async => [maths, art]);
    getIt.registerSingleton<DiaryRepository>(diary);
  });
  tearDown(getIt.reset);

  /// The screen as the page builds it: the diary bloc and the bloc of the class, section and day, which tells the diary
  /// bloc what is chosen.
  Widget screen({
    bool mayWrite = true,
    bool Function(DiaryEntry entry)? mayChange,
    bool started = true,
  }) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => DiaryBloc(diary)),
      BlocProvider(
        create: (_) {
          final bloc = SectionDayBloc(() => load(), clock: () => today);
          return started ? (bloc..add(const SectionDayStarted())) : bloc;
        },
      ),
    ],
    child: SectionDayListener(
      onChosen: (context, chosen) => context.read<DiaryBloc>().add(
        chosen.selection == null ? const DiaryCleared() : DiaryRead(sectionId: chosen.sectionId, day: chosen.day),
      ),
      child: Scaffold(
        body: DiaryView(parent: false, mayWrite: mayWrite, mayChange: mayChange ?? (_) => true),
      ),
    ),
  );

  /// Opens the staff screen; [mayChange] says whose entries the person may edit and delete.
  Future<void> pump(
    WidgetTester tester, {
    bool mayWrite = true,
    bool Function(DiaryEntry entry)? mayChange,
    double textScale = 1,
    Size size = const Size(400, 1400),
  }) async {
    await tester.pumpAppScaled(
      screen(mayWrite: mayWrite, mayChange: mayChange),
      textScale: textScale,
      size: size,
    );
    await tester.pumpAndSettle();
  }

  /// A parent's screen: the diary of the child shown, and the day to choose.
  Widget parentScreen() => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => DiaryBloc(diary, studentId: 's1')),
      BlocProvider(create: (_) => SectionDayBloc.dayOnly(clock: () => today)..add(const SectionDayStarted())),
    ],
    child: SectionDayListener(
      onChosen: (context, chosen) => context.read<DiaryBloc>().add(DiaryRead(day: chosen.day)),
      child: const Scaffold(body: DiaryView(parent: true)),
    ),
  );

  Future<void> pumpParent(WidgetTester tester, {double textScale = 1, Size size = const Size(400, 1400)}) async {
    when(() => diary.ofChild('s1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
    await tester.pumpAppScaled(parentScreen(), textScale: textScale, size: size);
    await tester.pumpAndSettle();
  }

  group('reading the classes', () {
    testWidgets('shows a placeholder while it reads', (tester) async {
      await tester.pumpAppScaled(screen(started: false));
      expect(find.byType(Semantics), findsWidgets);
      expect(find.byKey(const Key('diary.class')), findsNothing);
    });

    testWidgets('says plainly when the person may not see it', (tester) async {
      load = () async => throw refusal('FORBIDDEN', status: 403);
      await pump(tester);
      expect(find.byKey(const Key('diary.forbidden')), findsOneWidget);
    });

    testWidgets('says the same for any other refusal, which Try again cannot cure', (tester) async {
      load = () async => throw refusal('NOT_ASSIGNED', status: 403);
      await pump(tester);
      expect(find.byKey(const Key('diary.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says why it could not read, and reads again on Try again', (tester) async {
      var calls = 0;
      load = () async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return oneSection.choices;
      };
      await pump(tester);
      expect(find.byKey(const Key('diary.failed')), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diary.class')), findsOneWidget);
    });

    testWidgets('with no classes, says so', (tester) async {
      load = () async => (classes: const <ClassChoice>[], sections: const <SectionChoice>[]);
      await pump(tester);
      expect(find.byKey(const Key('diary.noSections')), findsOneWidget);
    });

    testWidgets('with a choice, asks for the class and the section first', (tester) async {
      load = () async => twoClasses.choices;
      await pump(tester);
      expect(find.byKey(const Key('diary.pick')), findsOneWidget);
      await tester.tap(find.byKey(const Key('diary.class')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7th').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('diary.section')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('7th · A').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diary.pick')), findsNothing);
      expect(find.text('Bring crayons.'), findsOneWidget);
    });
  });

  group('the entries', () {
    testWidgets('show the subject, the day, the description and who wrote each', (tester) async {
      await pump(tester);
      final card = find.byKey(const ValueKey('diary.entry.d1'));
      for (final text in ['Mathematics', '17-11-2026', 'Exercise 4.2, questions 1 to 5.', 'By: R. Nair']) {
        expect(
          find.descendant(of: card, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
    });

    testWidgets('leave out "By" for an entry no teacher wrote', (tester) async {
      await pump(tester);
      final card = find.byKey(const ValueKey('diary.entry.d3'));
      expect(find.descendant(of: card, matching: find.textContaining('By:')), findsNothing);
    });

    testWidgets('say plainly when the day has none', (tester) async {
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => const []);
      await pump(tester);
      expect(find.byKey(const Key('diary.empty')), findsOneWidget);
    });

    testWidgets('say why they could not be read, and read again on Try again', (tester) async {
      var calls = 0;
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('NOT_ASSIGNED', status: 403);
        return [mathsEntry];
      });
      await pump(tester);
      expect(find.byKey(const Key('diary.entriesFailed')), findsOneWidget);
      expect(find.text('You can read the diary of a section you lead or teach.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Mathematics'), findsOneWidget);
    });

    testWidgets('read whole at a large text scale on a small phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      // A date wider than the field it sits in cannot fit any box on a 320 px phone at this scale.
      expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
    });
  });

  group('who may change them', () {
    testWidgets('a person who may change an entry is offered Edit and Delete on it, and on no other', (tester) async {
      await pump(tester, mayChange: (entry) => entry.teacherId == 't1');
      expect(find.byKey(const ValueKey('diary.edit.d1')), findsOneWidget);
      expect(find.byKey(const ValueKey('diary.delete.d1')), findsOneWidget);
      expect(find.byKey(const ValueKey('diary.edit.d2')), findsNothing);
      expect(find.byKey(const ValueKey('diary.delete.d2')), findsNothing);
    });

    testWidgets('a person who may write is offered Add entry, and one who may not is not', (tester) async {
      await pump(tester);
      expect(find.byKey(const Key('diary.add')), findsOneWidget);
    });

    testWidgets('a person who only reads is offered none of them', (tester) async {
      await pump(tester, mayWrite: false, mayChange: (_) => false);
      expect(find.byKey(const Key('diary.add')), findsNothing);
      expect(find.byKey(const ValueKey('diary.edit.d1')), findsNothing);
      expect(find.byKey(const ValueKey('diary.delete.d1')), findsNothing);
      expect(find.text('Mathematics'), findsWidgets);
    });

    testWidgets('a parent reads their child’s entries and is offered nothing to change', (tester) async {
      await pumpParent(tester);
      expect(find.byKey(const Key('diary.class')), findsNothing);
      expect(find.text('Exercise 4.2, questions 1 to 5.'), findsOneWidget);
      expect(find.byKey(const Key('diary.add')), findsNothing);
      expect(find.byKey(const ValueKey('diary.edit.d1')), findsNothing);
      verify(() => diary.ofChild('s1', '2026-11-17')).called(1);
    });

    testWidgets('a parent whose child is blocked is told so', (tester) async {
      when(() => diary.ofChild('s1', '2026-11-17')).thenThrow(refusal('CHILD_ACCESS_BLOCKED', status: 403));
      await tester.pumpAppScaled(parentScreen(), size: const Size(400, 1400));
      await tester.pumpAndSettle();
      expect(find.text("Access to this child's information is blocked. Contact the school."), findsOneWidget);
    });
  });

  group('adding an entry', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('diary.add')));
      await tester.pumpAndSettle();
    }

    Future<void> fill(WidgetTester tester, {String subject = 'Art', String text = 'Bring crayons tomorrow.'}) async {
      await tester.tap(find.byKey(const Key('diaryForm.subject')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(subject).last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('diaryForm.description')), text);
    }

    testWidgets('sends the subject, the day shown and the description, then reads that day again', (tester) async {
      when(() => diary.add('sec1', any())).thenAnswer((_) async => artEntry);
      await pump(tester);
      await open(tester);
      expect(find.text('Add diary entry'), findsOneWidget);
      await fill(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      verify(
        () => diary.add(
          'sec1',
          const DiaryInput(subjectId: 'u2', day: '2026-11-17', description: 'Bring crayons tomorrow.'),
        ),
      ).called(1);
      expect(find.text('Diary entry saved'), findsOneWidget);
      expect(find.byKey(const Key('diaryForm.save')), findsNothing);
      // Once for the screen opening, once for what was saved.
      verify(() => diary.ofSection('sec1', '2026-11-17')).called(2);
    });

    testWidgets('shows the day an entry was saved for, not the day that was open', (tester) async {
      const earlier = DiaryEntry(
        id: 'd4',
        version: 1,
        sectionId: 'sec1',
        subjectId: 'u2',
        subjectName: 'Art',
        day: '2026-11-16',
        description: 'Bring crayons.',
      );
      when(() => diary.add('sec1', any())).thenAnswer((_) async => earlier);
      when(() => diary.ofSection('sec1', '2026-11-16')).thenAnswer((_) async => [earlier]);
      await pump(tester);
      await open(tester);
      await fill(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      verify(() => diary.ofSection('sec1', '2026-11-16')).called(1);
      expect(
        find.descendant(of: find.byKey(const Key('diary.day')), matching: find.text('16-11-2026')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('diary.entry.d4')), findsOneWidget);
    });

    testWidgets('lets the day be picked up to today and no later', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('diaryForm.day')));
      await tester.pumpAndSettle();
      final next = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right));
      expect(next.onPressed, isNull, reason: 'November 2026 is the last month with a day to pick');
    });

    testWidgets('stops the description at the longest the server takes', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.enterText(find.byKey(const Key('diaryForm.description')), 'a' * (maxDiaryDescription + 50));
      final field = tester.widget<TextField>(
        find.descendant(of: find.byKey(const Key('diaryForm.description')), matching: find.byType(TextField)),
      );
      expect(field.controller!.text.length, maxDiaryDescription);
    });

    testWidgets('shows a refused field under it only, not also above the form', (tester) async {
      when(() => diary.add('sec1', any())).thenThrow(
        const ApiFailure(
          statusCode: 400,
          code: 'VALIDATION_FAILED',
          message: 'server words',
          fieldErrors: [FieldError(field: 'description', code: 'REQUIRED', message: 'x')],
        ),
      );
      await pump(tester);
      await open(tester);
      await fill(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);
      expect(find.byKey(const Key('diaryForm.error')), findsNothing);
    });

    testWidgets('names a subject or a description left empty, and sends nothing', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsNWidgets(2));
      verifyNever(() => diary.add(any(), any()));
    });

    testWidgets('says above the form why a save was refused, and keeps what was written', (tester) async {
      when(() => diary.add('sec1', any())).thenThrow(refusal('NOT_ASSIGNED', status: 403));
      await pump(tester);
      await open(tester);
      await fill(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.error')), findsOneWidget);
      expect(
        find.text(
          'You can write the diary for a subject you teach in a section, or any subject of a section you lead.',
        ),
        findsOneWidget,
      );
      expect(find.text('Bring crayons tomorrow.'), findsOneWidget);
    });

    testWidgets('offers no Try again for subjects it was refused, which asking again does not change', (tester) async {
      when(() => diary.subjects('sec1')).thenThrow(refusal('NOT_ASSIGNED', status: 403));
      await pump(tester);
      await open(tester);
      expect(find.byKey(const Key('diaryForm.loadFailed')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says why the subjects could not be read, and reads them again on Try again', (tester) async {
      var calls = 0;
      when(() => diary.subjects('sec1')).thenAnswer((_) async {
        if (++calls == 1) throw refusal('SERVER_ERROR', status: 500);
        return [maths, art];
      });
      await pump(tester);
      await open(tester);
      expect(find.byKey(const Key('diaryForm.loadFailed')), findsOneWidget);
      await tester.tap(
        find.descendant(of: find.byKey(const Key('diaryForm.loadFailed')), matching: find.text('Try again')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.subject')), findsOneWidget);
    });

    testWidgets('with no subject open to write for, says so and offers no Save', (tester) async {
      when(() => diary.subjects('sec1')).thenAnswer((_) async => const []);
      await pump(tester);
      await open(tester);
      expect(find.byKey(const Key('diaryForm.noSubjects')), findsOneWidget);
      expect(find.byKey(const Key('diaryForm.save')), findsNothing);
      expect(find.byKey(const Key('diaryForm.subject')), findsNothing);
      await tester.tap(find.byKey(const Key('diaryForm.cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.noSubjects')), findsNothing);
      verifyNever(() => diary.add(any(), any()));
    });

    testWidgets('says it whole at a large text scale on a small phone', (tester) async {
      when(() => diary.subjects('sec1')).thenAnswer((_) async => const []);
      await pump(tester, textScale: 3, size: const Size(320, 640));
      await open(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('diaryForm.noSubjects')), findsOneWidget);
    });

    testWidgets('closes on Cancel without saving', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('diaryForm.cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.save')), findsNothing);
      verifyNever(() => diary.add(any(), any()));
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, textScale: 2, size: const Size(320, 640));
      await tester.tap(find.byKey(const Key('diary.add')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // A date wider than the field it sits in cannot fit any box on a 320 px phone at this scale.
      expect(clippedParagraphs(tester, unbreakable: 320 - 6 * 16), isEmpty);
    });
  });

  group('editing an entry', () {
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('diary.edit.d1')));
      await tester.pumpAndSettle();
    }

    testWidgets('opens on the entry, and sends only what was changed with its version', (tester) async {
      when(() => diary.change(any(), any())).thenAnswer((_) async => mathsEntry);
      await pump(tester);
      await open(tester);
      expect(find.text('Edit diary entry'), findsOneWidget);
      expect(find.text('Exercise 4.2, questions 1 to 5.'), findsWidgets);
      await tester.enterText(find.byKey(const Key('diaryForm.description')), 'Exercise 4.3.');
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      verify(
        () => diary.change(
          mathsEntry,
          const DiaryInput(subjectId: 'u1', day: '2026-11-17', description: 'Exercise 4.3.'),
        ),
      ).called(1);
      expect(find.text('Diary entry saved'), findsOneWidget);
    });

    testWidgets('asks for the subject again when the entry’s subject is no longer offered', (tester) async {
      when(() => diary.subjects('sec1')).thenAnswer((_) async => [art]);
      await pump(tester);
      await open(tester);
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);
      verifyNever(() => diary.change(any(), any()));
    });

    testWidgets('keeps the day of an entry older than the window, which a text correction does not check', (
      tester,
    ) async {
      const old = DiaryEntry(
        id: 'd9',
        version: 2,
        sectionId: 'sec1',
        subjectId: 'u1',
        subjectName: 'Mathematics',
        day: '2026-11-02',
        description: 'Old note.',
        teacherId: 't1',
        teacherName: 'R. Nair',
      );
      when(() => diary.ofSection('sec1', any())).thenAnswer((_) async => [old]);
      when(() => diary.change(any(), any())).thenAnswer((_) async => old);
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('diary.edit.d9')));
      await tester.pumpAndSettle();
      // The calendar opens on the entry's day, which is before the last 7 days, and confirming it keeps that day.
      await tester.tap(find.byKey(const Key('diaryForm.day')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('diaryForm.description')), 'Old note, corrected.');
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      verify(
        () => diary.change(
          old,
          const DiaryInput(subjectId: 'u1', day: '2026-11-02', description: 'Old note, corrected.'),
        ),
      ).called(1);
    });

    testWidgets('on an entry changed meanwhile, says so and hands back to the list, which reads the day again', (
      tester,
    ) async {
      when(() => diary.change(any(), any())).thenThrow(refusal('VERSION_CONFLICT', status: 409));
      await pump(tester);
      await open(tester);
      await tester.enterText(find.byKey(const Key('diaryForm.description')), 'Exercise 4.3.');
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.error')), findsOneWidget);
      await tester.tap(find.byKey(const Key('diaryForm.backToList')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diaryForm.save')), findsNothing);
      verify(() => diary.ofSection('sec1', '2026-11-17')).called(2);
      expect(find.text('Diary entry saved'), findsNothing);
    });

    testWidgets('on an entry removed meanwhile, Cancel hands back to the list too', (tester) async {
      when(() => diary.change(any(), any())).thenThrow(refusal('NOT_FOUND', status: 404));
      await pump(tester);
      await open(tester);
      await tester.enterText(find.byKey(const Key('diaryForm.description')), 'Exercise 4.3.');
      await tester.tap(find.byKey(const Key('diaryForm.save')));
      await tester.pumpAndSettle();
      expect(find.text('This entry could not be found. It may have been deleted.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('diaryForm.cancel')));
      await tester.pumpAndSettle();
      verify(() => diary.ofSection('sec1', '2026-11-17')).called(2);
    });
  });

  group('deleting an entry', () {
    Future<void> ask(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('diary.delete.d1')));
      await tester.pumpAndSettle();
    }

    testWidgets('asks first, and removes the entry from the list once confirmed', (tester) async {
      when(() => diary.remove('d1')).thenAnswer((_) async {});
      await pump(tester);
      await ask(tester);
      expect(find.text('Delete this entry?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      verify(() => diary.remove('d1')).called(1);
      expect(find.byKey(const ValueKey('diary.entry.d1')), findsNothing);
      expect(find.byKey(const ValueKey('diary.entry.d2')), findsOneWidget);
    });

    testWidgets('takes no other choice of class, section or day while the entry is going', (tester) async {
      final pending = Completer<void>();
      when(() => diary.remove('d1')).thenAnswer((_) => pending.future);
      await pump(tester);
      await ask(tester);
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      expect(tester.widget<MasterDropdown>(find.byKey(const Key('diary.class'))).onChanged, isNull);
      expect(tester.widget<MasterDropdown>(find.byKey(const Key('diary.section'))).onChanged, isNull);
      expect(tester.widget<DayField>(find.byKey(const Key('diary.day'))).onChanged, isNull);
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.widget<DayField>(find.byKey(const Key('diary.day'))).onChanged, isNotNull);
      expect(find.text('Diary entry deleted'), findsOneWidget);
    });

    testWidgets('keeps the entry when the person says Cancel', (tester) async {
      await pump(tester);
      await ask(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => diary.remove(any()));
      expect(find.byKey(const ValueKey('diary.entry.d1')), findsOneWidget);
    });

    testWidgets('says why a delete was refused and keeps the list', (tester) async {
      when(() => diary.remove('d1')).thenThrow(refusal('NOT_ASSIGNED', status: 403));
      await pump(tester);
      await ask(tester);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diary.actionFailed')), findsOneWidget);
      expect(find.text('Only the teacher who wrote this entry, an Owner or an Admin can change it.'), findsOneWidget);
      expect(find.byKey(const ValueKey('diary.entry.d1')), findsOneWidget);
    });

    testWidgets('shows the entry being deleted and starts no other change meanwhile', (tester) async {
      final pending = Completer<void>();
      when(() => diary.remove('d1')).thenAnswer((_) => pending.future);
      await pump(tester);
      await ask(tester);
      await tester.tap(find.text('Delete').last);
      await tester.pump();
      for (final key in [const ValueKey('diary.delete.d2'), const ValueKey('diary.edit.d2'), const Key('diary.add')]) {
        expect(tester.widget<AppButton>(find.byKey(key)).onPressed, isNull, reason: '$key');
      }
      pending.complete();
      await tester.pumpAndSettle();
    });
  });
}
