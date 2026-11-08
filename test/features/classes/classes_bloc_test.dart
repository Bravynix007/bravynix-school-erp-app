import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_bulk_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/class_form_bloc.dart';
import 'package:bravynix_school_erp/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/classes.dart';
import '../../helpers/mocks.dart';

const _duplicate = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');

void main() {
  late MockClassesRepository repository;
  late MockClassCatalogue catalogue;
  setUp(() {
    repository = MockClassesRepository();
    catalogue = MockClassCatalogue();
  });
  setUpAll(() => registerFallbackValue(const NewClass(predefinedClassId: '')));

  group('ClassesBloc', () {
    ClassesBloc build() => ClassesBloc(repository, 'i1');

    blocTest<ClassesBloc, ListState<SchoolClass>>(
      'loads the classes of its Institution',
      build: build,
      setUp: () => when(() => repository.classes('i1')).thenAnswer((_) async => [class1, pucClass]),
      act: (bloc) => bloc.add(const ListRequested()),
      expect: () => [
        const ListLoading<SchoolClass>(),
        const ListLoaded<SchoolClass>([class1, pucClass]),
      ],
    );

    blocTest<ClassesBloc, ListState<SchoolClass>>(
      'deactivates a class by its ID, then reads the classes again, saying which one went',
      build: build,
      setUp: () {
        var gone = false;
        when(() => repository.classes('i1')).thenAnswer((_) async => gone ? [pucClass] : [class1, pucClass]);
        when(() => repository.deactivate('k1')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<SchoolClass>);
        bloc.add(const ClassDeactivated(class1));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<SchoolClass>([class1, pucClass], busyId: 'k1'),
        const ListLoaded<SchoolClass>([pucClass], changed: class1),
      ],
    );
  });

  group('ClassFormBloc adding', () {
    ClassFormBloc build() => ClassFormBloc(repository, catalogue, 'i1');

    blocTest<ClassFormBloc, ClassFormState>(
      'reads what the Institution can add',
      build: build,
      setUp: () => when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice, pucChoice]),
      act: (bloc) => bloc.add(const ClassFormStarted()),
      expect: () => [
        const ClassFormLoading(),
        const ClassFormEditing(choices: [class1Choice, pucChoice]),
      ],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'keeps the failure when that cannot be read, and reads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => catalogue.offered('i1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [class1Choice];
        });
      },
      act: (bloc) async {
        bloc.add(const ClassFormStarted());
        await bloc.stream.firstWhere((state) => state is ClassFormFailed);
        bloc.add(const ClassFormStarted());
      },
      expect: () => [
        const ClassFormLoading(),
        const ClassFormFailed(ApiFailure.network()),
        const ClassFormLoading(),
        const ClassFormEditing(choices: [class1Choice]),
      ],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'adds the class picked, leaving out an empty name and code',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice]);
        when(() => repository.create('i1', const NewClass(predefinedClassId: 'p1'))).thenAnswer((_) async => class1);
      },
      act: (bloc) async {
        bloc.add(const ClassFormStarted());
        await bloc.stream.firstWhere((state) => state is ClassFormEditing);
        bloc.add(
          const ClassFormSubmitted(
            ClassFields(choice: class1Choice, streamName: ' ', displayName: '  ', code: ''),
          ),
        );
      },
      skip: 2,
      expect: () => [
        const ClassFormEditing(choices: [class1Choice], saving: true),
        const ClassFormSaved(class1),
      ],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'sends the stream of a Pre-University class, trimmed, with the name and code',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [pucChoice]);
        when(
          () => repository.create(
            'i1',
            const NewClass(predefinedClassId: 'p9', streamName: 'PCMC'),
            displayName: 'PUC',
            code: 'P1',
          ),
        ).thenAnswer((_) async => pucClass);
      },
      act: (bloc) async {
        bloc.add(const ClassFormStarted());
        await bloc.stream.firstWhere((state) => state is ClassFormEditing);
        bloc.add(
          const ClassFormSubmitted(
            ClassFields(choice: pucChoice, streamName: ' PCMC ', displayName: ' PUC ', code: ' P1 '),
          ),
        );
      },
      skip: 2,
      expect: () => [
        const ClassFormEditing(choices: [pucChoice], saving: true),
        const ClassFormSaved(pucClass),
      ],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'sends no stream for a class that allows none, even when one was typed before the class was changed',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice]);
        when(() => repository.create('i1', const NewClass(predefinedClassId: 'p1'))).thenAnswer((_) async => class1);
      },
      act: (bloc) async {
        bloc.add(const ClassFormStarted());
        await bloc.stream.firstWhere((state) => state is ClassFormEditing);
        bloc.add(
          const ClassFormSubmitted(ClassFields(choice: class1Choice, streamName: 'PCMC', displayName: '', code: '')),
        );
      },
      skip: 2,
      expect: () => [
        const ClassFormEditing(choices: [class1Choice], saving: true),
        const ClassFormSaved(class1),
      ],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'keeps the form open with the reason, and the choices, when the save is refused',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice]);
        when(() => repository.create('i1', const NewClass(predefinedClassId: 'p1'))).thenThrow(_duplicate);
      },
      act: (bloc) async {
        bloc.add(const ClassFormStarted());
        await bloc.stream.firstWhere((state) => state is ClassFormEditing);
        bloc.add(
          const ClassFormSubmitted(ClassFields(choice: class1Choice, streamName: '', displayName: '', code: '')),
        );
      },
      skip: 2,
      expect: () => [
        const ClassFormEditing(choices: [class1Choice], saving: true),
        const ClassFormEditing(choices: [class1Choice], failure: _duplicate),
      ],
    );
  });

  group('ClassFormBloc editing', () {
    ClassFormBloc build() => ClassFormBloc(repository, catalogue, 'i1', existing: class1);

    blocTest<ClassFormBloc, ClassFormState>(
      'starts open with nothing to read',
      build: build,
      act: (bloc) => bloc.add(const ClassFormStarted()),
      expect: () => <ClassFormState>[],
      verify: (_) => verifyNever(() => catalogue.offered(any())),
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'changes the name and the code with the version it read, and clears an emptied code',
      build: build,
      setUp: () => when(() => repository.update(class1, displayName: 'One')).thenAnswer((_) async => class1),
      act: (bloc) => bloc.add(const ClassFormSubmitted(ClassFields(streamName: '', displayName: ' One ', code: ' '))),
      expect: () => [const ClassFormEditing(saving: true), const ClassFormSaved(class1)],
    );

    blocTest<ClassFormBloc, ClassFormState>(
      'does not save twice while a save is on its way',
      build: build,
      setUp: () => when(() => repository.update(class1, displayName: 'One')).thenAnswer(
        (_) => Future<Never>.delayed(const Duration(milliseconds: 10), () => throw _duplicate),
      ),
      act: (bloc) => bloc
        ..add(const ClassFormSubmitted(ClassFields(streamName: '', displayName: 'One', code: '')))
        ..add(const ClassFormSubmitted(ClassFields(streamName: '', displayName: 'One', code: ''))),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => repository.update(class1, displayName: 'One')).called(1),
    );
  });

  group('ClassBulkBloc', () {
    ClassBulkBloc build() => ClassBulkBloc(repository, catalogue, 'i1');

    blocTest<ClassBulkBloc, ClassBulkState>(
      'offers the classes without a stream; those of Pre-University are added one at a time',
      build: build,
      setUp: () => when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice, class2Choice, pucChoice]),
      act: (bloc) => bloc.add(const ClassBulkStarted()),
      expect: () => [
        const ClassBulkLoading(),
        const ClassBulkEditing(choices: [class1Choice, class2Choice]),
      ],
    );

    blocTest<ClassBulkBloc, ClassBulkState>(
      'keeps the failure when the choices cannot be read',
      build: build,
      setUp: () => when(() => catalogue.offered('i1')).thenThrow(const ApiFailure.network()),
      act: (bloc) => bloc.add(const ClassBulkStarted()),
      expect: () => [const ClassBulkLoading(), const ClassBulkFailed(ApiFailure.network())],
    );

    blocTest<ClassBulkBloc, ClassBulkState>(
      'adds the classes ticked, all or none',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice, class2Choice]);
        when(
          () =>
              repository.createMany('i1', const [NewClass(predefinedClassId: 'p1'), NewClass(predefinedClassId: 'p2')]),
        ).thenAnswer((_) async => [class1]);
      },
      act: (bloc) async {
        bloc.add(const ClassBulkStarted());
        await bloc.stream.firstWhere((state) => state is ClassBulkEditing);
        bloc.add(const ClassBulkSubmitted(['p1', 'p2']));
      },
      skip: 2,
      expect: () => [
        const ClassBulkEditing(choices: [class1Choice, class2Choice], saving: true),
        const ClassBulkSaved([class1]),
      ],
    );

    blocTest<ClassBulkBloc, ClassBulkState>(
      'keeps the list open with the reason when the add is refused',
      build: build,
      setUp: () {
        when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice]);
        when(() => repository.createMany(any(), any())).thenThrow(_duplicate);
      },
      act: (bloc) async {
        bloc.add(const ClassBulkStarted());
        await bloc.stream.firstWhere((state) => state is ClassBulkEditing);
        bloc.add(const ClassBulkSubmitted(['p1']));
      },
      skip: 2,
      expect: () => [
        const ClassBulkEditing(choices: [class1Choice], saving: true),
        const ClassBulkEditing(choices: [class1Choice], failure: _duplicate, sent: ['p1']),
      ],
    );

    blocTest<ClassBulkBloc, ClassBulkState>(
      'asks for nothing when nothing is ticked',
      build: build,
      setUp: () => when(() => catalogue.offered('i1')).thenAnswer((_) async => [class1Choice]),
      act: (bloc) async {
        bloc.add(const ClassBulkStarted());
        await bloc.stream.firstWhere((state) => state is ClassBulkEditing);
        bloc.add(const ClassBulkSubmitted([]));
      },
      skip: 2,
      expect: () => <ClassBulkState>[],
      verify: (_) => verifyNever(() => repository.createMany(any(), any())),
    );
  });
}
