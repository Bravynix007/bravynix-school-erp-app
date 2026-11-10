import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/bloc/institution_form_bloc.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

const _texts = InstitutionTexts(name: ' Lake View School ', code: ' LVS ', addressLine1: ' 3 Hill Street ');

void main() {
  late MockInstitutionsRepository institutions;
  late MockMastersRepository masters;

  setUpAll(() {
    registerFallbackValue(const InstitutionDraft(name: 'x', code: 'x', addressLine1: 'x', classesOffered: []));
    registerFallbackValue(MasterType.countries);
  });

  setUp(() {
    institutions = MockInstitutionsRepository();
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async => [lowerPrimary, higherPrimary]);
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(
      () => masters.entries(MasterType.states, parentId: 'k1'),
    ).thenAnswer((_) async => [karnataka, kerala]);
    when(
      () => masters.entries(MasterType.cities, parentId: 's1'),
    ).thenAnswer((_) async => [bengaluru, mysuru]);
    when(() => masters.entries(MasterType.cities, parentId: 's2')).thenAnswer((_) async => [kochi]);
  });

  InstitutionFormBloc build({String? id}) => InstitutionFormBloc(institutions, masters, institutionId: id);

  const addReady = InstitutionFormReady(
    categories: [lowerPrimary, higherPrimary],
    countries: [india],
    states: [karnataka, kerala],
    countryId: 'k1',
  );

  group('adding', () {
    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'starts in India, the only country, with its states',
      build: build,
      act: (bloc) => bloc.add(const InstitutionFormStarted()),
      expect: () => [const InstitutionFormLoading(), addReady],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'asks for the country when there is more than one',
      build: build,
      setUp: () => when(
        () => masters.entries(MasterType.countries),
      ).thenAnswer((_) async => [india, const MasterEntry(id: 'k2', name: 'Nepal')]),
      act: (bloc) => bloc.add(const InstitutionFormStarted()),
      expect: () => [
        const InstitutionFormLoading(),
        const InstitutionFormReady(
          categories: [lowerPrimary, higherPrimary],
          countries: [
            india,
            MasterEntry(id: 'k2', name: 'Nepal'),
          ],
        ),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'keeps the failure for the screen, and starts again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.classCategories)).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [lowerPrimary, higherPrimary];
        });
      },
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormFailed);
        bloc.add(const InstitutionFormStarted());
      },
      expect: () => [
        const InstitutionFormLoading(),
        const InstitutionFormFailed(ApiFailure.network()),
        const InstitutionFormLoading(),
        addReady,
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'ticks and unticks a category, and picks a board',
      build: build,
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc
          ..add(const InstitutionCategoryToggled('c1'))
          ..add(const InstitutionCategoryToggled('c2'))
          ..add(const InstitutionCategoryToggled('c1'))
          ..add(const InstitutionBoardChosen(Board.icse));
      },
      skip: 2,
      expect: () => [
        isA<InstitutionFormReady>().having((s) => s.categoryIds, 'categoryIds', ['c1']),
        isA<InstitutionFormReady>().having((s) => s.categoryIds, 'categoryIds', ['c1', 'c2']),
        isA<InstitutionFormReady>().having((s) => s.categoryIds, 'categoryIds', ['c2']),
        isA<InstitutionFormReady>().having((s) => s.board, 'board', Board.icse),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'a state brings its cities, and another state empties the city',
      build: build,
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc.add(const InstitutionStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady && state.cities.isNotEmpty);
        bloc.add(const InstitutionCityChosen('y2'));
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady && state.cityId == 'y2');
        bloc.add(const InstitutionStateChosen('s2'));
      },
      skip: 2,
      expect: () => [
        isA<InstitutionFormReady>()
            .having((s) => s.stateId, 'stateId', 's1')
            .having((s) => s.cities, 'cities', isEmpty),
        isA<InstitutionFormReady>().having((s) => s.cities, 'cities', [bengaluru, mysuru]),
        isA<InstitutionFormReady>().having((s) => s.cityId, 'cityId', 'y2'),
        isA<InstitutionFormReady>()
            .having((s) => s.stateId, 'stateId', 's2')
            .having((s) => s.cityId, 'cityId', isNull)
            .having((s) => s.cities, 'cities', isEmpty),
        isA<InstitutionFormReady>().having((s) => s.cities, 'cities', [kochi]),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'the cities of the state chosen last win, however late the earlier list arrives',
      build: build,
      setUp: () {
        final late = Completer<List<MasterEntry>>();
        when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) => late.future);
        when(() => masters.entries(MasterType.cities, parentId: 's2')).thenAnswer((_) async {
          // The answer for the first state comes after this one.
          Future<void>.delayed(const Duration(milliseconds: 10), () => late.complete([bengaluru, mysuru]));
          return [kochi];
        });
      },
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc
          ..add(const InstitutionStateChosen('s1'))
          ..add(const InstitutionStateChosen('s2'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (bloc) {
        final ready = bloc.state as InstitutionFormReady;
        expect(ready.stateId, 's2');
        expect(ready.cities, [kochi]);
      },
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'another country empties the state and the city, and clearing the state loads nothing',
      build: build,
      setUp: () {
        when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
        when(() => masters.entries(MasterType.states, parentId: 'k2')).thenAnswer((_) async => const []);
      },
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc.add(const InstitutionStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady && state.cities.isNotEmpty);
        bloc
          ..add(const InstitutionCountryChosen('k2'))
          ..add(const InstitutionCountryChosen(null));
      },
      skip: 4,
      expect: () => [
        isA<InstitutionFormReady>()
            .having((s) => s.countryId, 'countryId', 'k2')
            .having((s) => s.stateId, 'stateId', isNull)
            .having((s) => s.states, 'states', isEmpty)
            .having((s) => s.cities, 'cities', isEmpty),
        isA<InstitutionFormReady>().having((s) => s.countryId, 'countryId', isNull),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'a list that cannot be read is kept as the failure, and the choice stays',
      build: build,
      setUp: () => when(
        () => masters.entries(MasterType.cities, parentId: 's1'),
      ).thenThrow(const ApiFailure.network()),
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc.add(const InstitutionStateChosen('s1'));
      },
      skip: 2,
      expect: () => [
        isA<InstitutionFormReady>().having((s) => s.stateId, 'stateId', 's1'),
        isA<InstitutionFormReady>()
            .having((s) => s.failure, 'failure', const ApiFailure.network())
            .having((s) => s.stateId, 'stateId', 's1'),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'sends what was typed, trimmed, and the chosen lists, then reports the saved Institution',
      build: build,
      setUp: () => when(() => institutions.create(any())).thenAnswer((_) async => bareInstitution),
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc
          ..add(const InstitutionCategoryToggled('c2'))
          ..add(const InstitutionBoardChosen(Board.cbse))
          ..add(const InstitutionStateChosen('s1'))
          ..add(const InstitutionCityChosen('y1'));
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady && state.cityId == 'y1');
        bloc.add(
          const InstitutionFormSubmitted(
            InstitutionTexts(
              name: ' Lake View School ',
              code: ' LVS ',
              addressLine1: ' 3 Hill Street ',
              gstin: ' 29abcde1234f1z5 ',
              phoneCountryCode: '91',
              phoneNumber: ' 9876543210 ',
              pincode: '   ',
            ),
          ),
        );
      },
      verify: (_) {
        final draft = verify(() => institutions.create(captureAny())).captured.single as InstitutionDraft;
        expect(
          draft,
          const InstitutionDraft(
            name: 'Lake View School',
            code: 'LVS',
            addressLine1: '3 Hill Street',
            classesOffered: ['c2'],
            board: Board.cbse,
            gstin: '29ABCDE1234F1Z5',
            phone: Phone(countryCode: '91', number: '9876543210'),
            countryId: 'k1',
            stateId: 's1',
            cityId: 'y1',
          ),
        );
      },
      expect: () => [
        isA<InstitutionFormReady>(),
        isA<InstitutionFormReady>(),
        isA<InstitutionFormReady>(),
        isA<InstitutionFormReady>(),
        isA<InstitutionFormReady>(),
        isA<InstitutionFormReady>().having((s) => s.saving, 'saving', isTrue),
        const InstitutionFormSaved(bareInstitution),
      ],
      skip: 2,
    );

    for (final (name, texts, phone) in [
      (
        'sends no phone for a country code alone',
        const InstitutionTexts(name: 'a', code: 'b', addressLine1: 'c', phoneCountryCode: '91'),
        null,
      ),
      (
        'sends the dial code without a plus and the number without spaces',
        const InstitutionTexts(
          name: 'a',
          code: 'b',
          addressLine1: 'c',
          phoneCountryCode: ' +91 ',
          phoneNumber: '98765 43210',
        ),
        const Phone(countryCode: '91', number: '9876543210'),
      ),
      (
        'sends a number without its country code as it is, so the API names the field',
        const InstitutionTexts(name: 'a', code: 'b', addressLine1: 'c', phoneNumber: '98'),
        const Phone(countryCode: '', number: '98'),
      ),
    ]) {
      blocTest<InstitutionFormBloc, InstitutionFormState>(
        name,
        build: build,
        setUp: () => when(() => institutions.create(any())).thenAnswer((_) async => bareInstitution),
        act: (bloc) async {
          bloc.add(const InstitutionFormStarted());
          await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
          bloc.add(InstitutionFormSubmitted(texts));
        },
        verify: (_) {
          final draft = verify(() => institutions.create(captureAny())).captured.single as InstitutionDraft;
          expect(draft.phone, phone);
        },
        expect: () => anything,
      );
    }

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'keeps the form, with the failure, when the save is refused',
      build: build,
      setUp: () => when(() => institutions.create(any())).thenThrow(
        const ApiFailure(
          statusCode: 409,
          code: 'DUPLICATE',
          message: 'x',
          fieldErrors: [FieldError(field: 'code', code: 'DUPLICATE', message: 'In use')],
        ),
      ),
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc.add(const InstitutionFormSubmitted(_texts));
      },
      skip: 2,
      expect: () => [
        isA<InstitutionFormReady>().having((s) => s.saving, 'saving', isTrue),
        isA<InstitutionFormReady>()
            .having((s) => s.saving, 'saving', isFalse)
            .having((s) => s.failure?.code, 'failure', 'DUPLICATE'),
      ],
    );
  });

  group('editing', () {
    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'starts from the Institution, with its categories, board and place chosen',
      build: () => build(id: 'i1'),
      setUp: () => when(() => institutions.institution('i1')).thenAnswer((_) async => institution),
      act: (bloc) => bloc.add(const InstitutionFormStarted()),
      expect: () => [
        const InstitutionFormLoading(),
        const InstitutionFormReady(
          existing: institution,
          categories: [lowerPrimary, higherPrimary],
          countries: [india],
          states: [karnataka, kerala],
          cities: [bengaluru, mysuru],
          board: Board.cbse,
          categoryIds: ['c1', 'c2'],
          countryId: 'k1',
          stateId: 's1',
          cityId: 'y1',
        ),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'lists a category the Institution offers although it is hidden now, so saving does not drop it',
      build: () => build(id: 'i1'),
      setUp: () {
        when(() => institutions.institution('i1')).thenAnswer((_) async => institution);
        when(() => masters.entries(MasterType.classCategories))
            .thenAnswer((_) async => [lowerPrimary, seniorSecondary]);
      },
      act: (bloc) => bloc.add(const InstitutionFormStarted()),
      verify: (bloc) {
        final ready = bloc.state as InstitutionFormReady;
        expect(ready.categories.map((c) => c.name), ['Lower Primary', 'Senior Secondary', 'Higher Primary']);
        expect(ready.categoryIds, ['c1', 'c2']);
      },
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'says the Institution is missing when it cannot be read',
      build: () => build(id: 'i1'),
      setUp: () => when(
        () => institutions.institution('i1'),
      ).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      act: (bloc) => bloc.add(const InstitutionFormStarted()),
      expect: () => [
        const InstitutionFormLoading(),
        const InstitutionFormFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      ],
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'sends the version it read and the code it has, and an emptied field as not set',
      build: () => build(id: 'i1'),
      setUp: () {
        when(() => institutions.institution('i1')).thenAnswer((_) async => institution);
        when(() => institutions.update(any(), any(), any())).thenAnswer((_) async => institution);
      },
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc.add(
          const InstitutionFormSubmitted(
            InstitutionTexts(name: 'New name', code: 'IGNORED', addressLine1: '12 Lake Road'),
          ),
        );
      },
      verify: (_) {
        final call = verify(() => institutions.update('i1', 3, captureAny())).captured.single as InstitutionDraft;
        expect(call.name, 'New name');
        expect(call.code, 'SVHS');
        expect(call.place, isNull);
        expect(call.classesOffered, ['c1', 'c2']);
        expect(call.cityId, 'y1');
      },
      expect: () => anything,
    );

    blocTest<InstitutionFormBloc, InstitutionFormState>(
      'does not save twice while a save is on its way',
      build: () => build(id: 'i1'),
      setUp: () {
        when(() => institutions.institution('i1')).thenAnswer((_) async => institution);
        when(() => institutions.update(any(), any(), any())).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return institution;
        });
      },
      act: (bloc) async {
        bloc.add(const InstitutionFormStarted());
        await bloc.stream.firstWhere((state) => state is InstitutionFormReady);
        bloc
          ..add(const InstitutionFormSubmitted(_texts))
          ..add(const InstitutionFormSubmitted(_texts));
      },
      verify: (_) => verify(() => institutions.update(any(), any(), any())).called(1),
      expect: () => anything,
    );
  });
}
