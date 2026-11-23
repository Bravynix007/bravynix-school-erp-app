import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/diary.dart';
import '../../helpers/mocks.dart';

ApiFailure refusal(String code, {int status = 403}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockDiaryRepository diary;
  setUp(() {
    diary = MockDiaryRepository();
    when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry, artEntry]);
  });

  DiaryBloc staff() => DiaryBloc(diary);

  /// Opens the diary of section A of the 7th for today and waits for its entries.
  Future<DiaryBloc> open() async {
    final bloc = staff()..add(const DiaryRead(sectionId: 'sec1', day: '2026-11-17'));
    await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded);
    return bloc;
  }

  List<DiaryEntry> entriesOf(DiaryBloc bloc) => (bloc.state as DiaryBoardLoaded).entries;

  group('staff', () {
    test('have nothing read until a section is chosen', () async {
      final bloc = staff();
      expect(bloc.state, const DiaryBoardEmpty());
      bloc.add(const DiaryReloaded());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const DiaryBoardEmpty());
      verifyNever(() => diary.ofSection(any(), any()));
      await bloc.close();
    });

    blocTest<DiaryBloc, DiaryBoard>(
      'read the entries of the section and day chosen, in the order written',
      build: staff,
      act: (bloc) => bloc.add(const DiaryRead(sectionId: 'sec1', day: '2026-11-17')),
      expect: () => [
        const DiaryBoardLoading(),
        const DiaryBoardLoaded([mathsEntry, artEntry]),
      ],
    );

    test('put the entries away when no section is chosen any more', () async {
      final bloc = await open();
      bloc.add(const DiaryCleared());
      await bloc.stream.firstWhere((state) => state is DiaryBoardEmpty);
      await bloc.close();
    });

    test('are shown why the entries cannot be read, and read them again on Try again', () async {
      when(() => diary.ofSection('sec1', '2026-11-17')).thenThrow(refusal('NOT_ASSIGNED'));
      final bloc = staff()..add(const DiaryRead(sectionId: 'sec1', day: '2026-11-17'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardFailed);
      expect((bloc.state as DiaryBoardFailed).failure, refusal('NOT_ASSIGNED'));
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryReloaded());
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded);
      expect(entriesOf(bloc), [mathsEntry]);
      await bloc.close();
    });

    test('do not see the answer for a day they have left', () async {
      final slow = Completer<List<DiaryEntry>>();
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-16')).thenAnswer((_) => slow.future);
      when(() => diary.ofSection('sec1', '2026-11-15')).thenAnswer((_) async => [artEntry]);
      bloc.add(const DiaryRead(sectionId: 'sec1', day: '2026-11-16'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoading);
      bloc.add(const DiaryRead(sectionId: 'sec1', day: '2026-11-15'));
      await bloc.stream.firstWhere((state) => state == const DiaryBoardLoaded([artEntry]));
      slow.complete([mathsEntry]);
      await Future<void>.delayed(Duration.zero);
      expect(entriesOf(bloc), [artEntry]);
      await bloc.close();
    });

    test('do not see the answer for a section they have left', () async {
      final slow = Completer<List<DiaryEntry>>();
      when(() => diary.ofSection('sec3', '2026-11-17')).thenAnswer((_) => slow.future);
      final bloc = staff()..add(const DiaryRead(sectionId: 'sec3', day: '2026-11-17'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoading);
      bloc.add(const DiaryCleared());
      await bloc.stream.firstWhere((state) => state is DiaryBoardEmpty);
      slow.complete([mathsEntry]);
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, const DiaryBoardEmpty());
      await bloc.close();
    });

    test('read the list again after an entry was added or changed', () async {
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryReloaded());
      await bloc.stream.firstWhere((state) => state == const DiaryBoardLoaded([mathsEntry]));
      await bloc.close();
    });

    test('delete an entry, which then leaves the list', () async {
      when(() => diary.remove('d1')).thenAnswer((_) async {});
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(mathsEntry));
      await bloc.stream.firstWhere((state) => state == const DiaryBoardLoaded([artEntry]));
      verify(() => diary.remove('d1')).called(1);
      await bloc.close();
    });

    test('are shown why a delete was refused, with the list as it was', () async {
      when(() => diary.remove('d2')).thenThrow(refusal('NOT_ASSIGNED'));
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(artEntry));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded && state.failure != null);
      expect(bloc.state, DiaryBoardLoaded(const [mathsEntry, artEntry], failure: refusal('NOT_ASSIGNED')));
      await bloc.close();
    });

    test('read the list again when the entry was already removed', () async {
      when(() => diary.remove('d2')).thenThrow(refusal('NOT_FOUND', status: 404));
      final bloc = await open();
      when(() => diary.ofSection('sec1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      bloc.add(const DiaryEntryRemoved(artEntry));
      await bloc.stream.firstWhere((state) => state == const DiaryBoardLoaded([mathsEntry]));
      await bloc.close();
    });

    test('take no second delete while an entry is being deleted', () async {
      final pending = Completer<void>();
      when(() => diary.remove('d1')).thenAnswer((_) => pending.future);
      final bloc = await open();
      bloc.add(const DiaryEntryRemoved(mathsEntry));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded && state.removing == 'd1');
      bloc.add(const DiaryEntryRemoved(artEntry));
      await Future<void>.delayed(Duration.zero);
      verifyNever(() => diary.remove('d2'));
      pending.complete();
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded && state.removing == null);
      await bloc.close();
    });
  });

  group('a parent', () {
    DiaryBloc parent() => DiaryBloc(diary, studentId: 's1');

    test("reads their child's entries for the day chosen, and no section", () async {
      when(() => diary.ofChild('s1', '2026-11-17')).thenAnswer((_) async => [mathsEntry]);
      final bloc = parent()..add(const DiaryRead(day: '2026-11-17'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded);
      expect(bloc.state, const DiaryBoardLoaded([mathsEntry]));
      verifyNever(() => diary.ofSection(any(), any()));
      await bloc.close();
    });

    test('read another day of their child', () async {
      when(() => diary.ofChild('s1', any())).thenAnswer((_) async => const []);
      final bloc = parent()..add(const DiaryRead(day: '2026-11-17'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded);
      bloc.add(const DiaryRead(day: '2026-11-16'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoading);
      await bloc.stream.firstWhere((state) => state is DiaryBoardLoaded);
      verify(() => diary.ofChild('s1', '2026-11-16')).called(1);
      await bloc.close();
    });

    test('are told when their child is blocked', () async {
      when(() => diary.ofChild('s1', '2026-11-17')).thenThrow(refusal('CHILD_ACCESS_BLOCKED'));
      final bloc = parent()..add(const DiaryRead(day: '2026-11-17'));
      await bloc.stream.firstWhere((state) => state is DiaryBoardFailed);
      expect((bloc.state as DiaryBoardFailed).failure.code, 'CHILD_ACCESS_BLOCKED');
      await bloc.close();
    });
  });
}
