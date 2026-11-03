import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
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
    blocTest<SubjectsBloc, SubjectsState>(
      'loads the subjects',
      build: () => SubjectsBloc(repository),
      setUp: () => when(() => repository.subjects()).thenAnswer((_) async => [maths, art]),
      act: (bloc) => bloc.add(const SubjectsRequested()),
      expect: () => [
        const SubjectsLoading(),
        const SubjectsLoaded([maths, art]),
      ],
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'keeps the failure for the screen, and loads again on retry',
      build: () => SubjectsBloc(repository),
      setUp: () {
        var calls = 0;
        when(() => repository.subjects()).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [maths];
        });
      },
      act: (bloc) async {
        bloc.add(const SubjectsRequested());
        await bloc.stream.firstWhere((state) => state is SubjectsFailed);
        bloc.add(const SubjectsRequested());
      },
      expect: () => [
        const SubjectsLoading(),
        const SubjectsFailed(ApiFailure.network()),
        const SubjectsLoading(),
        const SubjectsLoaded([maths]),
      ],
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'deactivates a subject, then reads the subjects again, saying which one went',
      build: () => SubjectsBloc(repository),
      setUp: () {
        var gone = false;
        when(() => repository.subjects()).thenAnswer((_) async => gone ? [art] : [maths, art]);
        when(() => repository.deactivate('u1')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const SubjectsRequested());
        await bloc.stream.firstWhere((state) => state is SubjectsLoaded);
        bloc.add(const SubjectDeactivated(maths));
      },
      skip: 2,
      expect: () => [
        const SubjectsLoaded([maths, art], busyId: 'u1'),
        const SubjectsLoaded([art], deactivated: maths),
      ],
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'says why a deactivation was refused, with the list read again',
      build: () => SubjectsBloc(repository),
      setUp: () {
        when(() => repository.subjects()).thenAnswer((_) async => [maths]);
        when(() => repository.deactivate('u1')).thenThrow(
          const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'),
        );
      },
      act: (bloc) async {
        bloc.add(const SubjectsRequested());
        await bloc.stream.firstWhere((state) => state is SubjectsLoaded);
        bloc.add(const SubjectDeactivated(maths));
      },
      skip: 2,
      expect: () => [
        const SubjectsLoaded([maths], busyId: 'u1'),
        const SubjectsLoaded([maths], actionFailure: ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
      verify: (_) => verify(() => repository.subjects()).called(2),
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'fails the screen when the list cannot be read again after a deactivation',
      build: () => SubjectsBloc(repository),
      setUp: () {
        var calls = 0;
        when(() => repository.subjects()).thenAnswer((_) async {
          if (++calls == 2) throw const ApiFailure.network();
          return [maths];
        });
        when(() => repository.deactivate('u1')).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const SubjectsRequested());
        await bloc.stream.firstWhere((state) => state is SubjectsLoaded);
        bloc.add(const SubjectDeactivated(maths));
      },
      skip: 2,
      expect: () => [
        const SubjectsLoaded([maths], busyId: 'u1'),
        const SubjectsFailed(ApiFailure.network()),
      ],
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'does not start a second deactivation while one is on its way',
      build: () => SubjectsBloc(repository),
      setUp: () {
        when(() => repository.subjects()).thenAnswer((_) async => [maths]);
        when(() => repository.deactivate(any()))
            .thenAnswer((_) => Future<void>.delayed(const Duration(milliseconds: 10)));
      },
      act: (bloc) async {
        bloc.add(const SubjectsRequested());
        await bloc.stream.firstWhere((state) => state is SubjectsLoaded);
        bloc
          ..add(const SubjectDeactivated(maths))
          ..add(const SubjectDeactivated(maths));
      },
      expect: () => anything,
      verify: (_) => verify(() => repository.deactivate('u1')).called(1),
    );

    blocTest<SubjectsBloc, SubjectsState>(
      'ignores a deactivation before the subjects are shown',
      build: () => SubjectsBloc(repository),
      act: (bloc) => bloc.add(const SubjectDeactivated(maths)),
      expect: () => <SubjectsState>[],
      verify: (_) => verifyNever(() => repository.deactivate(any())),
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
