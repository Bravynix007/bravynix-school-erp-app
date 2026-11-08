import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/section_form_bloc.dart';
import 'package:bravynix_school_erp/features/sections/presentation/bloc/sections_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/sections.dart';

const _duplicate = ApiFailure(statusCode: 409, code: 'DUPLICATE', message: 'x');

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

    blocTest<SectionsBloc, ListState<Section>>(
      'loads the sections of its class',
      build: build,
      setUp: () => when(() => repository.sections('k1')).thenAnswer((_) async => [sectionA, sectionB]),
      act: (bloc) => bloc.add(const ListRequested()),
      expect: () => [
        const ListLoading<Section>(),
        const ListLoaded<Section>([sectionA, sectionB]),
      ],
    );

    blocTest<SectionsBloc, ListState<Section>>(
      'deactivates a section by its ID, then reads the sections again, saying which one went',
      build: build,
      setUp: () {
        var gone = false;
        when(() => repository.sections('k1')).thenAnswer((_) async => gone ? [sectionB] : [sectionA, sectionB]);
        when(() => repository.deactivate('e1')).thenAnswer((_) async => gone = true);
      },
      act: (bloc) async {
        bloc.add(const ListRequested());
        await bloc.stream.firstWhere((state) => state is ListLoaded<Section>);
        bloc.add(const SectionDeactivated(sectionA));
      },
      skip: 2,
      expect: () => [
        const ListLoaded<Section>([sectionA, sectionB], busyId: 'e1'),
        const ListLoaded<Section>([sectionB], changed: sectionA),
      ],
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
