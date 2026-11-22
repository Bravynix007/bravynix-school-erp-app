import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/attendance.dart';
import '../../helpers/diary.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 403}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockDiaryRepository diary;
  late MockAttendanceRepository attendance;
  setUp(() {
    diary = MockDiaryRepository();
    attendance = MockAttendanceRepository();
    when(() => attendance.sections('i1')).thenAnswer((_) async => twoClasses);
    when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry, artEntry]);
  });

  DiaryBloc staff() => DiaryBloc(diary, attendance, institutionId: 'i1', clock: () => today);

  /// Opens the staff screen on section A of the 7th and waits for its entries.
  Future<DiaryBloc> open() async {
    final bloc = staff()..add(const DiaryStarted());
    await bloc.stream.firstWhere((state) => state is DiaryReady);
    bloc
      ..add(const DiaryClassChosen('c7'))
      ..add(const DiarySectionChosen('sec1'));
    await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
    return bloc;
  }

  List<DiaryEntry> entriesOf(DiaryBloc bloc) => ((bloc.state as DiaryReady).board as DiaryBoardLoaded).entries;

  group('staff', () {
    test('are offered the classes and sections of the Institution, and today, with nothing read yet', () async {
      final bloc = staff()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady);
      expect(bloc.state, DiaryReady(classes: twoClasses.classes, sections: twoClasses.sections, day: '2026-11-17'));
      verifyNever(() => diary.ofSection(any(), any()));
      await bloc.close();
    });

    test('are told when the classes cannot be read, and read them again on Try again', () async {
      when(() => attendance.sections('i1')).thenThrow(refusal('FORBIDDEN'));
      final bloc = staff()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryFailed);
      expect(bloc.state, DiaryFailed(refusal('FORBIDDEN')));
      when(() => attendance.sections('i1')).thenAnswer((_) async => twoClasses);
      bloc.add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady);
      await bloc.close();
    });

    test('read the entries of the section chosen, in the order written', () async {
      final bloc = await open();
      expect(
        bloc.state,
        DiaryReady(
          classes: twoClasses.classes,
          sections: twoClasses.sections,
          day: '2026-11-17',
          classId: 'c7',
          sectionId: 'sec1',
          board: const DiaryBoardLoaded([mathsEntry, artEntry]),
        ),
      );
      await bloc.close();
    });

    test('have a class with one section chosen for them, and a school with one class too', () async {
      when(() => attendance.sections('i1')).thenAnswer((_) async => oneSection);
      final bloc = staff()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
      expect((bloc.state as DiaryReady).sectionId, 'sec1');
      expect((bloc.state as DiaryReady).classId, 'c7');
      await bloc.close();
    });

    test('choose a section again when the class changes, and read nothing until they do', () async {
      final bloc = await open();
      clearInteractions(diary);
      bloc.add(const DiaryClassChosen('c8'));
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.classId == 'c8');
      final state = bloc.state as DiaryReady;
      expect([state.sectionId, state.board], [null, const DiaryBoardEmpty()]);
      // The 8th has one section, so it is chosen for them.
      when(() => diary.ofSection('sec3', '2026-11-17')).thenAnswer((_) async => const []);
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
      verify(() => diary.ofSection('sec3', '2026-11-17')).called(1);
      await bloc.close();
    });

    test('read the entries of another day', () async {
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-16')).thenAnswer((_) async => [artEntry]);
      bloc.add(const DiaryDayChosen('2026-11-16'));
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board == const DiaryBoardLoaded([artEntry]));
      expect(entriesOf(bloc), [artEntry]);
      await bloc.close();
    });

    test('are shown why the entries cannot be read, and read them again on Try again', () async {
      when(() => diary.ofSection('sec1', '2026-11-17')).thenThrow(refusal('NOT_ASSIGNED'));
      final bloc = staff()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady);
      bloc
        ..add(const DiaryClassChosen('c7'))
        ..add(const DiarySectionChosen('sec1'));
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardFailed);
      expect(((bloc.state as DiaryReady).board as DiaryBoardFailed).failure, refusal('NOT_ASSIGNED'));
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryRead());
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
      expect(entriesOf(bloc), [mathsEntry]);
      await bloc.close();
    });

    test('do not see the answer for a day they have left', () async {
      final slow = Completer<List<DiaryEntry>>();
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-16')).thenAnswer((_) => slow.future);
      when(() => diary.ofSection('sec1', '2026-11-15')).thenAnswer((_) async => [artEntry]);
      bloc.add(const DiaryDayChosen('2026-11-16'));
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoading);
      bloc.add(const DiaryDayChosen('2026-11-15'));
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && state.day == '2026-11-15' && state.board is DiaryBoardLoaded,
      );
      slow.complete([mathsEntry]);
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as DiaryReady).day, '2026-11-15');
      expect(entriesOf(bloc), [artEntry]);
      await bloc.close();
    });

    test('read the day an entry was written for after adding or changing it', () async {
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-12')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryRead(day: '2026-11-12'));
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && state.day == '2026-11-12' && state.board is DiaryBoardLoaded,
      );
      expect(entriesOf(bloc), [mathsEntry]);
      await bloc.close();
    });

    test('delete an entry, which then leaves the list', () async {
      when(() => diary.remove('d1')).thenAnswer((_) async {});
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(mathsEntry));
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board == const DiaryBoardLoaded([artEntry]));
      verify(() => diary.remove('d1')).called(1);
      await bloc.close();
    });

    test('are shown why a delete was refused, with the list as it was', () async {
      when(() => diary.remove('d2')).thenThrow(refusal('NOT_ASSIGNED'));
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(artEntry));
      await bloc.stream.firstWhere((state) => state is DiaryReady && (state.board as DiaryBoardLoaded).failure != null);
      expect(
        (bloc.state as DiaryReady).board,
        DiaryBoardLoaded(const [mathsEntry, artEntry], failure: refusal('NOT_ASSIGNED')),
      );
      await bloc.close();
    });

    test('read the list again when the entry was already removed', () async {
      when(() => diary.remove('d2')).thenThrow(refusal('NOT_FOUND', status: 404));
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryEntryRemoved(artEntry));
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && state.board == const DiaryBoardLoaded([mathsEntry]),
      );
      await bloc.close();
    });

    test('take no other choice while an entry is being deleted, and no second delete', () async {
      final pending = Completer<void>();
      when(() => diary.remove('d1')).thenAnswer((_) => pending.future);
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(mathsEntry));
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && (state.board as DiaryBoardLoaded).removing == 'd1',
      );
      bloc
        ..add(const DiaryDayChosen('2026-11-16'))
        ..add(const DiaryClassChosen('c8'))
        ..add(const DiaryEntryRemoved(artEntry));
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as DiaryReady).day, '2026-11-17');
      expect((bloc.state as DiaryReady).classId, 'c7');
      verifyNever(() => diary.remove('d2'));
      pending.complete();
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && (state.board as DiaryBoardLoaded).removing == null,
      );
      await bloc.close();
    });
  });

  group('a parent', () {
    DiaryBloc parent() => DiaryBloc(diary, attendance, studentId: 's1', clock: () => today);

    test("reads their child's entries for today at once, and no sections are read", () async {
      when(() => diary.ofChild('s1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      final bloc = parent()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
      expect(
        bloc.state,
        const DiaryReady(
          classes: [],
          sections: [],
          day: '2026-11-17',
          board: DiaryBoardLoaded([mathsEntry]),
        ),
      );
      verifyNever(() => attendance.sections(any()));
      verifyNever(() => diary.ofSection(any(), any()));
      await bloc.close();
    });

    test('read another day of their child', () async {
      when(() => diary.ofChild('s1', any())).thenAnswer((_) async => const []);
      final bloc = parent()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardLoaded);
      bloc.add(const DiaryDayChosen('2026-11-16'));
      await bloc.stream.firstWhere(
        (state) => state is DiaryReady && state.day == '2026-11-16' && state.board is DiaryBoardLoaded,
      );
      verify(() => diary.ofChild('s1', '2026-11-16')).called(1);
      await bloc.close();
    });

    test('are told when their child is blocked', () async {
      when(() => diary.ofChild('s1', '2026-11-17')).thenThrow(refusal('CHILD_ACCESS_BLOCKED'));
      final bloc = parent()..add(const DiaryStarted());
      await bloc.stream.firstWhere((state) => state is DiaryReady && state.board is DiaryBoardFailed);
      expect(((bloc.state as DiaryReady).board as DiaryBoardFailed).failure.code, 'CHILD_ACCESS_BLOCKED');
      await bloc.close();
    });
  });

  test('a screen reads the sections of an Institution or one child, not both and not neither', () {
    expect(() => DiaryBloc(diary, attendance, clock: () => today), throwsA(isA<AssertionError>()));
    expect(
      () => DiaryBloc(diary, attendance, institutionId: 'i1', studentId: 's1', clock: () => today),
      throwsA(isA<AssertionError>()),
    );
  });
}
