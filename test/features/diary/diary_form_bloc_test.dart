import 'dart:async';

import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';
import 'package:bravynix_school_erp/features/diary/presentation/bloc/diary_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/diary.dart';
import '../../helpers/mocks.dart';
import '../../helpers/subjects.dart';

ApiFailure refusal(String code, {int status = 422}) => ApiFailure(statusCode: status, code: code, message: code);

void main() {
  late MockDiaryRepository diary;
  late MockSubjectsRepository subjects;
  setUp(() {
    diary = MockDiaryRepository();
    subjects = MockSubjectsRepository();
    registerFallbackValue(const DiaryInput(subjectId: '', day: '', description: ''));
    registerFallbackValue(mathsEntry);
    when(subjects.subjects).thenAnswer((_) async => [maths, art]);
  });

  Future<DiaryFormBloc> open({DiaryEntry? existing}) async {
    final bloc = DiaryFormBloc(diary, subjects, sectionId: 'sec1', existing: existing)..add(const DiaryFormStarted());
    await bloc.stream.firstWhere((state) => state is DiaryFormEditing);
    return bloc;
  }

  const fields = DiaryFields(subjectId: 'u1', day: '2026-11-17', description: '  Exercise 4.2.  ');

  test('offers the subjects it is given, which are a teacher’s own', () async {
    final bloc = await open();
    expect(bloc.state, const DiaryFormEditing([maths, art]));
    await bloc.close();
  });

  test('is told when the subjects cannot be read, and reads them again on Try again', () async {
    when(subjects.subjects).thenThrow(refusal('FORBIDDEN', status: 403));
    final bloc = DiaryFormBloc(diary, subjects, sectionId: 'sec1')..add(const DiaryFormStarted());
    await bloc.stream.firstWhere((state) => state is DiaryFormLoadFailed);
    when(subjects.subjects).thenAnswer((_) async => [maths]);
    bloc.add(const DiaryFormStarted());
    await bloc.stream.firstWhere((state) => state is DiaryFormEditing);
    expect(bloc.state, const DiaryFormEditing([maths]));
    await bloc.close();
  });

  test('adds an entry with the description trimmed', () async {
    when(() => diary.add('sec1', any())).thenAnswer((_) async => mathsEntry);
    final bloc = await open()
      ..add(const DiaryFormSubmitted(fields));
    await bloc.stream.firstWhere((state) => state is DiaryFormSaved);
    expect(bloc.state, const DiaryFormSaved(mathsEntry));
    verify(
      () => diary.add('sec1', const DiaryInput(subjectId: 'u1', day: '2026-11-17', description: 'Exercise 4.2.')),
    ).called(1);
    await bloc.close();
  });

  test('changes the entry it was opened on, and adds none', () async {
    when(() => diary.change(any(), any())).thenAnswer((_) async => mathsEntry);
    final bloc = await open(existing: mathsEntry)
      ..add(const DiaryFormSubmitted(fields));
    await bloc.stream.firstWhere((state) => state is DiaryFormSaved);
    verify(
      () =>
          diary.change(mathsEntry, const DiaryInput(subjectId: 'u1', day: '2026-11-17', description: 'Exercise 4.2.')),
    ).called(1);
    verifyNever(() => diary.add(any(), any()));
    await bloc.close();
  });

  test('sends nothing without a subject or a description, and names both', () async {
    final bloc = await open()
      ..add(const DiaryFormSubmitted(DiaryFields(subjectId: null, day: '2026-11-17', description: '   ')));
    await bloc.stream.firstWhere((state) => state is DiaryFormEditing && state.failure != null);
    final failure = (bloc.state as DiaryFormEditing).failure!;
    expect([for (final error in failure.fieldErrors) error.field], ['subjectId', 'description']);
    verifyNever(() => diary.add(any(), any()));
    await bloc.close();
  });

  test('keeps the form and says why a save was refused', () async {
    when(() => diary.add('sec1', any())).thenThrow(refusal('DATE_TOO_OLD'));
    final bloc = await open()
      ..add(const DiaryFormSubmitted(fields));
    await bloc.stream.firstWhere((state) => state is DiaryFormEditing && state.failure != null);
    expect(bloc.state, DiaryFormEditing(const [maths, art], failure: refusal('DATE_TOO_OLD')));
    await bloc.close();
  });

  test('does not save twice while a save is on its way', () async {
    final pending = Completer<DiaryEntry>();
    when(() => diary.add('sec1', any())).thenAnswer((_) => pending.future);
    final bloc = await open()
      ..add(const DiaryFormSubmitted(fields))
      ..add(const DiaryFormSubmitted(fields));
    await bloc.stream.firstWhere((state) => state is DiaryFormEditing && state.saving);
    await Future<void>.delayed(Duration.zero);
    pending.complete(mathsEntry);
    await bloc.stream.firstWhere((state) => state is DiaryFormSaved);
    verify(() => diary.add('sec1', any())).called(1);
    await bloc.close();
  });
}
