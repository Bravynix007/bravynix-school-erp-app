import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subject_form_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/subjects.dart';

const _duplicate = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');

void main() {
  late MockSubjectsRepository repository;
  setUp(() => repository = MockSubjectsRepository());

  group('SubjectsBloc', () {
    blocTest<SubjectsBloc, ListState<Subject>>(
      'loads the Society subjects',
      build: () => SubjectsBloc(repository),
      setUp: () => when(() => repository.subjects()).thenAnswer((_) async => [maths, art]),
      act: (bloc) => bloc.add(const ListRequested()),
      expect: () => [
        const ListLoading<Subject>(),
        const ListLoaded<Subject>([maths, art]),
      ],
    );

    blocTest<SubjectsBloc, ListState<Subject>>(
      'deactivates a subject by its ID, then reads the subjects again, saying which one went',
      build: () => SubjectsBloc(repository),
      setUp: () {
        var gone = false;
        when(() => repository.subjects()).thenAnswer((_) async => gone ? [art] : [maths, art]);
        when(() => repository.deactivate('u1')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<Subject>);
        bloc.add(const SubjectDeactivated(maths));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<Subject>([maths, art], busyId: 'u1'),
        const ListLoaded<Subject>([art], changed: maths),
      ],
    );
  });

  group('SubjectFormBloc', () {
    blocTest<SubjectFormBloc, SubjectFormState>(
      'adds a subject, trimming the name and leaving out an empty code',
      build: () => SubjectFormBloc(repository),
      setUp: () => when(() => repository.create(name: 'Art')).thenAnswer((_) async => art),
      act: (bloc) => bloc.add(const SubjectFormSubmitted(SubjectFields(name: '  Art ', code: '  '))),
      expect: () => [const SubjectFormEditing(saving: true), const SubjectFormSaved(art)],
    );

    blocTest<SubjectFormBloc, SubjectFormState>(
      'changes a subject with the version it read, and clears the code when it was emptied',
      build: () => SubjectFormBloc(repository, existing: maths),
      setUp: () => when(() => repository.update(maths, name: 'Maths')).thenAnswer((_) async => maths),
      act: (bloc) => bloc.add(const SubjectFormSubmitted(SubjectFields(name: 'Maths', code: ''))),
      expect: () => [const SubjectFormEditing(saving: true), const SubjectFormSaved(maths)],
    );

    blocTest<SubjectFormBloc, SubjectFormState>(
      'sends the code trimmed',
      build: () => SubjectFormBloc(repository),
      setUp: () => when(() => repository.create(name: 'Mathematics', code: 'MATH')).thenAnswer((_) async => maths),
      act: (bloc) => bloc.add(const SubjectFormSubmitted(SubjectFields(name: 'Mathematics', code: ' MATH '))),
      expect: () => [const SubjectFormEditing(saving: true), const SubjectFormSaved(maths)],
    );

    blocTest<SubjectFormBloc, SubjectFormState>(
      'keeps the form open with the reason when the save is refused',
      build: () => SubjectFormBloc(repository),
      setUp: () => when(() => repository.create(name: 'Art')).thenThrow(_duplicate),
      act: (bloc) => bloc.add(const SubjectFormSubmitted(SubjectFields(name: 'Art', code: ''))),
      expect: () => [const SubjectFormEditing(saving: true), const SubjectFormEditing(failure: _duplicate)],
    );

    blocTest<SubjectFormBloc, SubjectFormState>(
      'does not save twice while a save is on its way',
      build: () => SubjectFormBloc(repository),
      setUp: () => when(
        () => repository.create(name: 'Art'),
      ).thenAnswer((_) => Future<Never>.delayed(const Duration(milliseconds: 10), () => throw _duplicate)),
      act: (bloc) => bloc
        ..add(const SubjectFormSubmitted(SubjectFields(name: 'Art', code: '')))
        ..add(const SubjectFormSubmitted(SubjectFields(name: 'Art', code: ''))),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => repository.create(name: 'Art')).called(1),
    );
  });
}
