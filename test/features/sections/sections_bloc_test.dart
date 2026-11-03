import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_form_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/sections_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

const _duplicate = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');
const _notFound = ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x');

void main() {
  late MockSectionsRepository repository;
  late MockMastersRepository masters;
  setUpAll(() => registerFallbackValue(MasterType.predefinedSections));
  setUp(() {
    repository = MockSectionsRepository();
    masters = MockMastersRepository();
  });

  group('SectionsBloc', () {
    SectionsBloc build() => SectionsBloc(repository, 'k1');

    blocTest<SectionsBloc, SectionsState>(
      'loads the sections of its class',
      build: build,
      setUp: () => when(() => repository.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]),
      act: (bloc) => bloc.add(const SectionsRequested()),
      expect: () => [
        const SectionsLoading(),
        const SectionsLoaded([sectionA, sectionB]),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'keeps the failure for the screen, and loads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.sections('k1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [sectionA];
        });
      },
      act: (bloc) async {
        bloc.add(const SectionsRequested());
        await bloc.stream.firstWhere((state) => state is SectionsFailed);
        bloc.add(const SectionsRequested());
      },
      expect: () => [
        const SectionsLoading(),
        const SectionsFailed(ApiFailure.network()),
        const SectionsLoading(),
        const SectionsLoaded([sectionA]),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'deactivates a section, then reads the sections again, saying which one went',
      build: build,
      setUp: () {
        var gone = false;
        when(() => repository.sections('k1')).thenAnswer((_) async => gone ? [sectionB] : [sectionA, sectionB]);
        when(() => repository.deactivate('e1')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const SectionsRequested());
        await bloc.stream.firstWhere((state) => state is SectionsLoaded);
        bloc.add(const SectionDeactivated(sectionA));
      },
      skip: 2,
      expect: () => [
        const SectionsLoaded([sectionA, sectionB], busyId: 'e1'),
        const SectionsLoaded([sectionB], deactivated: sectionA),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'says why a deactivation was refused, with the list read again',
      build: build,
      setUp: () {
        when(() => repository.sections('k1')).thenAnswer((_) async => [sectionA]);
        when(() => repository.deactivate('e1')).thenThrow(_notFound);
      },
      act: (bloc) async {
        bloc.add(const SectionsRequested());
        await bloc.stream.firstWhere((state) => state is SectionsLoaded);
        bloc.add(const SectionDeactivated(sectionA));
      },
      skip: 2,
      expect: () => [
        const SectionsLoaded([sectionA], busyId: 'e1'),
        const SectionsLoaded([sectionA], actionFailure: _notFound),
      ],
      verify: (_) => verify(() => repository.sections('k1')).called(2),
    );

    blocTest<SectionsBloc, SectionsState>(
      'fails the screen when the list cannot be read again after a deactivation',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => repository.sections('k1')).thenAnswer((_) async {
          if (++calls == 2) throw const ApiFailure.network();
          return [sectionA];
        });
        when(() => repository.deactivate('e1')).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const SectionsRequested());
        await bloc.stream.firstWhere((state) => state is SectionsLoaded);
        bloc.add(const SectionDeactivated(sectionA));
      },
      skip: 2,
      expect: () => [
        const SectionsLoaded([sectionA], busyId: 'e1'),
        const SectionsFailed(ApiFailure.network()),
      ],
    );

    blocTest<SectionsBloc, SectionsState>(
      'does not start a second deactivation while one is on its way',
      build: build,
      setUp: () {
        when(() => repository.sections('k1')).thenAnswer((_) async => [sectionA]);
        when(
          () => repository.deactivate(any()),
        ).thenAnswer((_) => Future<void>.delayed(const Duration(milliseconds: 10)));
      },
      act: (bloc) async {
        bloc.add(const SectionsRequested());
        await bloc.stream.firstWhere((state) => state is SectionsLoaded);
        bloc
          ..add(const SectionDeactivated(sectionA))
          ..add(const SectionDeactivated(sectionA));
      },
      expect: () => anything,
      verify: (_) => verify(() => repository.deactivate('e1')).called(1),
    );

    blocTest<SectionsBloc, SectionsState>(
      'ignores a deactivation before the sections are shown',
      build: build,
      act: (bloc) => bloc.add(const SectionDeactivated(sectionA)),
      expect: () => <SectionsState>[],
      verify: (_) => verifyNever(() => repository.deactivate(any())),
    );
  });

  group('SectionFormBloc adding', () {
    SectionFormBloc build({Set<String> taken = const {}}) => SectionFormBloc(repository, masters, 'k1', taken: taken);

    blocTest<SectionFormBloc, SectionFormState>(
      'offers the predefined sections the class does not have yet',
      build: () => build(taken: {'s1'}),
      setUp: () => when(
        () => masters.entries(MasterType.predefinedSections),
      ).thenAnswer((_) async => [sectionAEntry, sectionBEntry]),
      act: (bloc) => bloc.add(const SectionFormStarted()),
      expect: () => [
        const SectionFormLoading(),
        const SectionFormEditing(choices: [sectionBEntry]),
      ],
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'keeps the failure when they cannot be read, and reads again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.predefinedSections)).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [sectionAEntry];
        });
      },
      act: (bloc) async {
        bloc.add(const SectionFormStarted());
        await bloc.stream.firstWhere((state) => state is SectionFormFailed);
        bloc.add(const SectionFormStarted());
      },
      expect: () => [
        const SectionFormLoading(),
        const SectionFormFailed(ApiFailure.network()),
        const SectionFormLoading(),
        const SectionFormEditing(choices: [sectionAEntry]),
      ],
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'adds the section picked, leaving out an empty name and capacity',
      build: build,
      setUp: () {
        when(() => masters.entries(MasterType.predefinedSections)).thenAnswer((_) async => [sectionAEntry]);
        when(() => repository.create('k1', predefinedSectionId: 's1')).thenAnswer((_) async => sectionA);
      },
      act: (bloc) async {
        bloc.add(const SectionFormStarted());
        await bloc.stream.firstWhere((state) => state is SectionFormEditing);
        bloc.add(const SectionFormSubmitted(SectionFields(predefinedSectionId: 's1', displayName: '  ')));
      },
      skip: 2,
      expect: () => [
        const SectionFormEditing(choices: [sectionAEntry], saving: true),
        const SectionFormSaved(sectionA),
      ],
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'sends the name, trimmed, and the capacity',
      build: build,
      setUp: () {
        when(() => masters.entries(MasterType.predefinedSections)).thenAnswer((_) async => [sectionBEntry]);
        when(
          () => repository.create('k1', predefinedSectionId: 's2', displayName: 'Blue', capacity: 30),
        ).thenAnswer((_) async => sectionB);
      },
      act: (bloc) async {
        bloc.add(const SectionFormStarted());
        await bloc.stream.firstWhere((state) => state is SectionFormEditing);
        bloc.add(
          const SectionFormSubmitted(SectionFields(predefinedSectionId: 's2', displayName: ' Blue ', capacity: 30)),
        );
      },
      skip: 2,
      expect: () => [
        const SectionFormEditing(choices: [sectionBEntry], saving: true),
        const SectionFormSaved(sectionB),
      ],
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'keeps the form open with the reason, and the choices, when the save is refused',
      build: build,
      setUp: () {
        when(() => masters.entries(MasterType.predefinedSections)).thenAnswer((_) async => [sectionAEntry]);
        when(() => repository.create('k1', predefinedSectionId: 's1')).thenThrow(_duplicate);
      },
      act: (bloc) async {
        bloc.add(const SectionFormStarted());
        await bloc.stream.firstWhere((state) => state is SectionFormEditing);
        bloc.add(const SectionFormSubmitted(SectionFields(predefinedSectionId: 's1', displayName: '')));
      },
      skip: 2,
      expect: () => [
        const SectionFormEditing(choices: [sectionAEntry], saving: true),
        const SectionFormEditing(choices: [sectionAEntry], failure: _duplicate),
      ],
    );
  });

  group('SectionFormBloc editing', () {
    SectionFormBloc build() => SectionFormBloc(repository, masters, 'k1', existing: sectionA);

    blocTest<SectionFormBloc, SectionFormState>(
      'starts open with nothing to read',
      build: build,
      act: (bloc) => bloc.add(const SectionFormStarted()),
      expect: () => <SectionFormState>[],
      verify: (_) => verifyNever(() => masters.entries(any())),
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'changes the name and the capacity with the version it read, and clears an emptied capacity',
      build: build,
      setUp: () => when(() => repository.update(sectionA, displayName: 'Blue')).thenAnswer((_) async => sectionA),
      act: (bloc) => bloc.add(const SectionFormSubmitted(SectionFields(displayName: ' Blue '))),
      expect: () => [const SectionFormEditing(saving: true), const SectionFormSaved(sectionA)],
    );

    blocTest<SectionFormBloc, SectionFormState>(
      'does not save twice while a save is on its way',
      build: build,
      setUp: () => when(() => repository.update(sectionA, displayName: 'Blue', capacity: 30)).thenAnswer(
        (_) => Future<Never>.delayed(const Duration(milliseconds: 10), () => throw _duplicate),
      ),
      act: (bloc) => bloc
        ..add(const SectionFormSubmitted(SectionFields(displayName: 'Blue', capacity: 30)))
        ..add(const SectionFormSubmitted(SectionFields(displayName: 'Blue', capacity: 30))),
      wait: const Duration(milliseconds: 50),
      verify: (_) => verify(() => repository.update(sectionA, displayName: 'Blue', capacity: 30)).called(1),
    );
  });
}
