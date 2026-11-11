import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:bravynix_school_erp/features/masters/presentation/bloc/place_bloc.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/place_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/institutions.dart';
import '../../helpers/pump_app.dart';

class _MockPlaceBloc extends MockBloc<PlaceEvent, PlaceState> implements PlaceBloc;

const _ready = PlaceReady(
  countries: [india],
  states: [karnataka, kerala],
  cities: [bengaluru, mysuru],
  choice: PlaceChoice(countryId: 'k1', stateId: 's1', cityId: 'y1'),
);

void main() {
  late _MockPlaceBloc bloc;
  setUpAll(() => registerFallbackValue(const PlaceStarted()));
  setUp(() => bloc = _MockPlaceBloc());

  Future<void> pump(
    WidgetTester tester,
    PlaceState state, {
    String? countryError,
    String? stateError,
    String? cityError,
    double textScale = 1,
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      Scaffold(
        body: SingleChildScrollView(
          child: BlocProvider<PlaceBloc>.value(
            value: bloc,
            child: PlaceFields(
              keyPrefix: 'place',
              countryError: countryError,
              stateError: stateError,
              cityError: cityError,
            ),
          ),
        ),
      ),
      textScale: textScale,
      size: const Size(400, 900),
    );
  }

  DropdownButtonFormField<String?> dropdown(WidgetTester tester, String key) => tester.widget(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(DropdownButtonFormField<String?>)),
  );

  Future<void> choose(WidgetTester tester, String key, String option) async {
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the country, state and city chosen', (tester) async {
    await pump(tester, _ready);
    for (final text in ['India', 'Karnataka', 'Bengaluru']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('tells the bloc what is chosen from each list', (tester) async {
    await pump(tester, _ready);
    await choose(tester, 'place.country', 'India');
    verify(() => bloc.add(const PlaceCountryChosen('k1'))).called(1);
    await choose(tester, 'place.state', 'Kerala');
    verify(() => bloc.add(const PlaceStateChosen('s2'))).called(1);
    await choose(tester, 'place.city', 'Mysuru');
    verify(() => bloc.add(const PlaceCityChosen('y2'))).called(1);
  });

  testWidgets('a state is chosen within a country', (tester) async {
    await pump(tester, const PlaceReady(countries: [india]));
    expect(dropdown(tester, 'place.country').onChanged, isNotNull);
    expect(dropdown(tester, 'place.state').onChanged, isNull);
  });

  testWidgets('a city is chosen within a state', (tester) async {
    await pump(
      tester,
      const PlaceReady(
        countries: [india],
        states: [karnataka],
        choice: PlaceChoice(countryId: 'k1'),
      ),
    );
    expect(dropdown(tester, 'place.state').onChanged, isNotNull);
    expect(dropdown(tester, 'place.city').onChanged, isNull);
  });

  testWidgets('keeps a place held although its entry is not listed now, and says it is no longer offered', (
    tester,
  ) async {
    await pump(
      tester,
      const PlaceReady(
        countries: [india],
        states: [kerala],
        choice: PlaceChoice(countryId: 'k1', stateId: 's1'),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Karnataka'), findsNothing);
    expect(find.text('India'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('place.state')), matching: find.text('No longer offered (kept)')),
      findsOneWidget,
    );
    expect(dropdown(tester, 'place.state').initialValue, 's1');
  });

  testWidgets('says a held country and city are no longer offered too, and offers the listed ones to replace them', (
    tester,
  ) async {
    await pump(
      tester,
      const PlaceReady(
        countries: [],
        states: [karnataka],
        cities: [mysuru],
        choice: PlaceChoice(countryId: 'k9', stateId: 's1', cityId: 'y9'),
      ),
    );
    expect(find.text('No longer offered (kept)'), findsNWidgets(2));
    await choose(tester, 'place.city', 'Mysuru');
    verify(() => bloc.add(const PlaceCityChosen('y2'))).called(1);
  });

  testWidgets('shows a place nothing is held for as empty, not as no longer offered', (tester) async {
    await pump(tester, const PlaceReady(countries: [india], states: [karnataka]));
    expect(find.text('No longer offered (kept)'), findsNothing);
  });

  testWidgets('says what the API said under the country, the state and the city', (tester) async {
    await pump(
      tester,
      _ready,
      countryError: 'Not a country',
      stateError: 'Not a state of India',
      cityError: 'Not a city of Karnataka',
    );
    for (final text in ['Not a country', 'Not a state of India', 'Not a city of Karnataka']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('shows a placeholder while the lists load', (tester) async {
    await pump(tester, const PlaceLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(find.byKey(const Key('place.country')), findsNothing);
  });

  testWidgets('says why the lists could not be read, and starts again on Try again', (tester) async {
    await pump(tester, const PlaceFailed(ApiFailure.network()));
    expect(find.byKey(const Key('place.placeFailed')), findsOneWidget);
    expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
    await tester.tap(find.byKey(const Key('place.placeRetry')));
    verify(() => bloc.add(const PlaceStarted())).called(1);
  });

  group('a list that could not be read after a choice', () {
    final failed = _ready.copyWith(failure: () => const ApiFailure.network());

    testWidgets('is said under the lists, with the choice kept', (tester) async {
      await pump(tester, failed);
      expect(find.byKey(const Key('place.listFailed')), findsOneWidget);
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      final city = tester.getTopLeft(find.byKey(const Key('place.city'))).dy;
      expect(tester.getTopLeft(find.byKey(const Key('place.listFailed'))).dy, greaterThan(city));
      expect(find.text('Karnataka'), findsOneWidget);
    });

    testWidgets('reads the lists again on Try again', (tester) async {
      await pump(tester, failed);
      await tester.tap(find.byKey(const Key('place.listRetry')));
      verify(() => bloc.add(const PlaceListsRetried())).called(1);
    });

    testWidgets('is not shown when nothing failed', (tester) async {
      await pump(tester, _ready);
      expect(find.byKey(const Key('place.listFailed')), findsNothing);
    });
  });

  testWidgets('reads whole at a large text scale', (tester) async {
    await pump(tester, _ready.copyWith(failure: () => const ApiFailure.network()), textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 400 - 4 * 16), isEmpty);
  });
}
