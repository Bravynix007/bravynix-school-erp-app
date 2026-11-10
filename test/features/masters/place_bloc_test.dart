import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/masters/presentation/bloc/place_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/institutions.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockMastersRepository masters;

  setUpAll(() => registerFallbackValue(MasterType.countries));

  setUp(() {
    masters = MockMastersRepository();
    when(() => masters.entries(MasterType.countries)).thenAnswer((_) async => [india]);
    when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async => [karnataka, kerala]);
    when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async => [bengaluru, mysuru]);
    when(() => masters.entries(MasterType.cities, parentId: 's2')).thenAnswer((_) async => [kochi]);
  });

  PlaceBloc build({PlaceChoice initial = const PlaceChoice(), bool soleCountry = false}) =>
      PlaceBloc(masters, initial: initial, soleCountry: soleCountry);

  Future<void> started(PlaceBloc bloc) async {
    bloc.add(const PlaceStarted());
    await bloc.stream.firstWhere((state) => state is PlaceReady);
  }

  group('starting', () {
    blocTest<PlaceBloc, PlaceState>(
      'a new record starts in the only country, with its states',
      build: () => build(soleCountry: true),
      act: (bloc) => bloc.add(const PlaceStarted()),
      expect: () => [
        const PlaceLoading(),
        const PlaceReady(
          countries: [india],
          states: [karnataka, kerala],
          choice: PlaceChoice(countryId: 'k1'),
        ),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'asks for the country when there is more than one',
      build: () => build(soleCountry: true),
      setUp: () => when(
        () => masters.entries(MasterType.countries),
      ).thenAnswer((_) async => [india, const MasterEntry(id: 'k2', name: 'Nepal')]),
      act: (bloc) => bloc.add(const PlaceStarted()),
      expect: () => [
        const PlaceLoading(),
        const PlaceReady(
          countries: [
            india,
            MasterEntry(id: 'k2', name: 'Nepal'),
          ],
        ),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'an edit that holds no place is not given one',
      build: build,
      act: (bloc) => bloc.add(const PlaceStarted()),
      expect: () => [
        const PlaceLoading(),
        const PlaceReady(countries: [india]),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'starts from the place the record holds, with the lists of its state',
      build: () => build(
        initial: const PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1'),
      ),
      act: (bloc) => bloc.add(const PlaceStarted()),
      expect: () => [
        const PlaceLoading(),
        const PlaceReady(
          countries: [india],
          states: [karnataka, kerala],
          cities: [bengaluru, mysuru],
          choice: PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1'),
        ),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'keeps the failure for the screen, and starts again on retry',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.countries)).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [india];
        });
      },
      act: (bloc) async {
        bloc.add(const PlaceStarted());
        await bloc.stream.firstWhere((state) => state is PlaceFailed);
        bloc.add(const PlaceStarted());
      },
      expect: () => [
        const PlaceLoading(),
        const PlaceFailed(ApiFailure.network()),
        const PlaceLoading(),
        const PlaceReady(countries: [india]),
      ],
    );
  });

  group('choosing', () {
    blocTest<PlaceBloc, PlaceState>(
      'a state brings its cities, and another state empties the city',
      build: () => build(soleCountry: true),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.cities.isNotEmpty);
        bloc.add(const PlaceCityChosen('y2'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.choice.cityId == 'y2');
        bloc.add(const PlaceStateChosen('s2'));
      },
      skip: 2,
      expect: () => [
        isA<PlaceReady>().having((s) => s.choice.stateId, 'stateId', 's1').having((s) => s.cities, 'cities', isEmpty),
        isA<PlaceReady>().having((s) => s.cities, 'cities', [bengaluru, mysuru]),
        isA<PlaceReady>().having((s) => s.choice.cityId, 'cityId', 'y2'),
        isA<PlaceReady>()
            .having((s) => s.choice.stateId, 'stateId', 's2')
            .having((s) => s.choice.cityId, 'cityId', isNull)
            .having((s) => s.cities, 'cities', isEmpty),
        isA<PlaceReady>().having((s) => s.cities, 'cities', [kochi]),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'the cities of the state chosen last win, however late the earlier list arrives',
      build: () => build(soleCountry: true),
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
        await started(bloc);
        bloc
          ..add(const PlaceStateChosen('s1'))
          ..add(const PlaceStateChosen('s2'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (bloc) {
        final ready = bloc.state as PlaceReady;
        expect(ready.choice.stateId, 's2');
        expect(ready.cities, [kochi]);
      },
    );

    blocTest<PlaceBloc, PlaceState>(
      'another country empties the state and the city, and clearing the country loads nothing',
      build: () => build(soleCountry: true),
      setUp: () => when(() => masters.entries(MasterType.states, parentId: 'k2')).thenAnswer((_) async => const []),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.cities.isNotEmpty);
        bloc
          ..add(const PlaceCountryChosen('k2'))
          ..add(const PlaceCountryChosen(null));
      },
      skip: 4,
      expect: () => [
        isA<PlaceReady>()
            .having((s) => s.choice.countryId, 'countryId', 'k2')
            .having((s) => s.choice.stateId, 'stateId', isNull)
            .having((s) => s.states, 'states', isEmpty)
            .having((s) => s.cities, 'cities', isEmpty),
        isA<PlaceReady>().having((s) => s.choice.countryId, 'countryId', isNull),
      ],
      // The first country's states and Nepal's, and nothing for no country.
      verify: (_) => verify(() => masters.entries(MasterType.states, parentId: any(named: 'parentId'))).called(2),
    );

    blocTest<PlaceBloc, PlaceState>(
      'choosing the country again changes nothing',
      build: () => build(soleCountry: true),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceCountryChosen('k1'));
      },
      skip: 2,
      expect: () => <PlaceState>[],
    );

    blocTest<PlaceBloc, PlaceState>(
      'a list that cannot be read is kept as the failure, and the choice stays',
      build: () => build(soleCountry: true),
      setUp: () => when(() => masters.entries(MasterType.cities, parentId: 's1')).thenThrow(const ApiFailure.network()),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
      },
      skip: 2,
      expect: () => [
        isA<PlaceReady>().having((s) => s.choice.stateId, 'stateId', 's1'),
        isA<PlaceReady>()
            .having((s) => s.failure, 'failure', const ApiFailure.network())
            .having((s) => s.choice.stateId, 'stateId', 's1'),
      ],
    );

    blocTest<PlaceBloc, PlaceState>(
      'a place held although its entries are hidden now stays chosen',
      build: () => build(
        initial: const PlaceChoice(countryId: 'k1', stateId: 's9'),
      ),
      setUp: () => when(() => masters.entries(MasterType.cities, parentId: 's9')).thenAnswer((_) async => const []),
      act: (bloc) => bloc.add(const PlaceStarted()),
      verify: (bloc) => expect((bloc.state as PlaceReady).choice.stateId, 's9'),
    );

    blocTest<PlaceBloc, PlaceState>(
      'choosing the state again changes nothing',
      build: () => build(soleCountry: true),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.cities.isNotEmpty);
        bloc.add(const PlaceStateChosen('s1'));
      },
      skip: 4,
      expect: () => <PlaceState>[],
      verify: (_) => verify(() => masters.entries(MasterType.cities, parentId: 's1')).called(1),
    );

    blocTest<PlaceBloc, PlaceState>(
      'another country clears the failure of an old list',
      build: () => build(soleCountry: true),
      setUp: () => when(() => masters.entries(MasterType.cities, parentId: 's1')).thenThrow(const ApiFailure.network()),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure != null);
        bloc.add(const PlaceCountryChosen(null));
      },
      verify: (bloc) => expect((bloc.state as PlaceReady).failure, isNull),
    );

    blocTest<PlaceBloc, PlaceState>(
      'another state clears the failure of an old list',
      build: () => build(soleCountry: true),
      setUp: () => when(() => masters.entries(MasterType.cities, parentId: 's1')).thenThrow(const ApiFailure.network()),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure != null);
        bloc.add(const PlaceStateChosen('s2'));
      },
      verify: (bloc) {
        final ready = bloc.state as PlaceReady;
        expect(ready.failure, isNull);
        expect(ready.cities, [kochi]);
      },
    );

    blocTest<PlaceBloc, PlaceState>(
      'a failure of the list for an earlier choice, arriving late, is dropped',
      build: () => build(soleCountry: true),
      setUp: () {
        final late = Completer<List<MasterEntry>>();
        when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) => late.future);
        when(() => masters.entries(MasterType.cities, parentId: 's2')).thenAnswer((_) async {
          // The first state's list fails after this one has answered.
          Future<void>.delayed(const Duration(milliseconds: 10), () => late.completeError(const ApiFailure.network()));
          return [kochi];
        });
      },
      act: (bloc) async {
        await started(bloc);
        bloc
          ..add(const PlaceStateChosen('s1'))
          ..add(const PlaceStateChosen('s2'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      verify: (bloc) {
        final ready = bloc.state as PlaceReady;
        expect(ready.failure, isNull);
        expect(ready.cities, [kochi]);
      },
    );
  });

  group('trying again', () {
    blocTest<PlaceBloc, PlaceState>(
      'reads the states of the chosen country again after they failed, so one country is not a dead end',
      build: build,
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.states, parentId: 'k1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure.network();
          return [karnataka, kerala];
        });
      },
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceCountryChosen('k1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure != null);
        // Choosing the country again reads nothing, as it is already chosen.
        bloc
          ..add(const PlaceCountryChosen('k1'))
          ..add(const PlaceListsRetried());
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.states.isNotEmpty);
      },
      verify: (bloc) {
        final ready = bloc.state as PlaceReady;
        expect(ready.states, [karnataka, kerala]);
        expect(ready.failure, isNull);
        expect(ready.choice.countryId, 'k1');
        verify(() => masters.entries(MasterType.states, parentId: 'k1')).called(2);
      },
    );

    blocTest<PlaceBloc, PlaceState>(
      'reads the cities of the chosen state again after they failed, and fails again when they still do',
      build: () => build(soleCountry: true),
      setUp: () {
        var calls = 0;
        when(() => masters.entries(MasterType.cities, parentId: 's1')).thenAnswer((_) async {
          if (++calls < 3) throw const ApiFailure.network();
          return [bengaluru, mysuru];
        });
      },
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceStateChosen('s1'));
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure != null);
        bloc.add(const PlaceListsRetried());
        // The second read fails too: the message comes back.
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure == null);
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.failure != null);
        bloc.add(const PlaceListsRetried());
        await bloc.stream.firstWhere((state) => state is PlaceReady && state.cities.isNotEmpty);
      },
      verify: (bloc) {
        final ready = bloc.state as PlaceReady;
        expect(ready.cities, [bengaluru, mysuru]);
        expect(ready.failure, isNull);
        expect(ready.choice, const PlaceChoice(countryId: 'k1', stateId: 's1'));
        verify(() => masters.entries(MasterType.cities, parentId: 's1')).called(3);
      },
    );

    blocTest<PlaceBloc, PlaceState>(
      'reads nothing when no list is missing',
      build: () => build(soleCountry: true),
      act: (bloc) async {
        await started(bloc);
        bloc.add(const PlaceListsRetried());
      },
      verify: (_) {
        verify(() => masters.entries(MasterType.states, parentId: 'k1')).called(1);
        verifyNever(() => masters.entries(MasterType.cities, parentId: any(named: 'parentId')));
      },
    );
  });
}
