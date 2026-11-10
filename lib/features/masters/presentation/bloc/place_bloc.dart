import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
import 'package:equatable/equatable.dart';

sealed class PlaceEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the place, and Try again after the lists could not be read.
final class PlaceStarted extends PlaceEvent {
  const new();
}

final class PlaceCountryChosen extends PlaceEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class PlaceStateChosen extends PlaceEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class PlaceCityChosen extends PlaceEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

sealed class PlaceState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class PlaceLoading extends PlaceState {
  const new();
}

/// The lists the place starts from could not be read.
class PlaceFailed extends PlaceState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The place: what is chosen, and the lists it is chosen from. [failure] is the last list that could not be read.
class PlaceReady extends PlaceState {
  const new({
    required this.countries,
    this.states = const [],
    this.cities = const [],
    this.choice = const PlaceChoice(),
    this.failure,
  });

  final List<MasterEntry> countries;
  final List<MasterEntry> states;
  final List<MasterEntry> cities;
  final PlaceChoice choice;
  final ApiFailure? failure;

  PlaceReady copyWith({
    List<MasterEntry>? states,
    List<MasterEntry>? cities,
    PlaceChoice? choice,
    ApiFailure? Function()? failure,
  }) => PlaceReady(
    countries: countries,
    states: states ?? this.states,
    cities: cities ?? this.cities,
    choice: choice ?? this.choice,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [countries, states, cities, choice, failure];
}

/// Picks a country, a state of it and a city of that state from the shared lists (MST-01), for an address.
///
/// A place the record already holds is chosen from the start and stays chosen even when its entry has been hidden
/// since, so saving does not drop it. [soleCountry] starts a new record in the only country there is instead of asking
/// (India for now); an edit never fills in a place that was left empty.
class PlaceBloc extends Bloc<PlaceEvent, PlaceState> {
  new(this._masters, {this.initial = const PlaceChoice(), this.soleCountry = false}) : super(const PlaceLoading()) {
    on<PlaceStarted>(_onStarted);
    on<PlaceCountryChosen>(_onCountryChosen);
    on<PlaceStateChosen>(_onStateChosen);
    on<PlaceCityChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(choice: _choice(ready, cityId: event.id)))),
    );
  }

  final MastersRepository _masters;
  final PlaceChoice initial;
  final bool soleCountry;

  void _ready(void Function(PlaceReady ready) work) {
    if (state case final PlaceReady ready) work(ready);
  }

  static PlaceChoice _choice(PlaceReady ready, {String? cityId}) =>
      PlaceChoice(countryId: ready.choice.countryId, stateId: ready.choice.stateId, cityId: cityId);

  Future<void> _onStarted(PlaceStarted event, Emitter<PlaceState> emit) async {
    emit(const PlaceLoading());
    try {
      final countries = await _masters.entries(MasterType.countries);
      final countryId = initial.countryId ?? (soleCountry && countries.length == 1 ? countries.single.id : null);
      final states = countryId == null
          ? <MasterEntry>[]
          : await _masters.entries(MasterType.states, parentId: countryId);
      final stateId = initial.stateId;
      final cities = stateId == null ? <MasterEntry>[] : await _masters.entries(MasterType.cities, parentId: stateId);
      emit(
        PlaceReady(
          countries: countries,
          states: states,
          cities: cities,
          choice: PlaceChoice(countryId: countryId, stateId: stateId, cityId: initial.cityId),
        ),
      );
    } on ApiFailure catch (failure) {
      emit(PlaceFailed(failure));
    }
  }

  Future<void> _onCountryChosen(PlaceCountryChosen event, Emitter<PlaceState> emit) async {
    if (state case final PlaceReady ready) {
      if (event.id == ready.choice.countryId) return;
      // A state belongs to its country and a city to its state, so choosing another country empties both.
      final cleared = ready.copyWith(
        choice: PlaceChoice(countryId: event.id),
        states: const [],
        cities: const [],
        failure: () => null,
      );
      emit(cleared);
      if (event.id == null) return;
      await _loadPlaces(emit, MasterType.states, event.id!);
    }
  }

  Future<void> _onStateChosen(PlaceStateChosen event, Emitter<PlaceState> emit) async {
    if (state case final PlaceReady ready) {
      if (event.id == ready.choice.stateId) return;
      final cleared = ready.copyWith(
        choice: PlaceChoice(countryId: ready.choice.countryId, stateId: event.id),
        cities: const [],
        failure: () => null,
      );
      emit(cleared);
      if (event.id == null) return;
      await _loadPlaces(emit, MasterType.cities, event.id!);
    }
  }

  Future<void> _loadPlaces(Emitter<PlaceState> emit, MasterType type, String parentId) async {
    try {
      final entries = await _masters.entries(type, parentId: parentId);
      // The choice may have changed while the list was on its way; only the latest answer counts.
      if (state case final PlaceReady now when _asked(now, type, parentId)) {
        emit(type == MasterType.states ? now.copyWith(states: entries) : now.copyWith(cities: entries));
      }
    } on ApiFailure catch (failure) {
      if (state case final PlaceReady now when _asked(now, type, parentId)) {
        emit(now.copyWith(failure: () => failure));
      }
    }
  }

  bool _asked(PlaceReady now, MasterType type, String parentId) =>
      parentId == (type == MasterType.states ? now.choice.countryId : now.choice.stateId);
}
