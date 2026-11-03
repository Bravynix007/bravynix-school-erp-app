import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:equatable/equatable.dart';

/// The text fields of the form, as typed. An empty one is read as not set.
class InstitutionTexts extends Equatable {
  const new({
    required this.name,
    required this.code,
    required this.addressLine1,
    this.place = '',
    this.affiliationNumber = '',
    this.gstin = '',
    this.email = '',
    this.phoneCountryCode = '',
    this.phoneNumber = '',
    this.telephone = '',
    this.addressLine2 = '',
    this.pincode = '',
  });

  final String name;
  final String code;
  final String addressLine1;
  final String place;
  final String affiliationNumber;
  final String gstin;
  final String email;
  final String phoneCountryCode;
  final String phoneNumber;
  final String telephone;
  final String addressLine2;
  final String pincode;

  @override
  List<Object?> get props => [
    name,
    code,
    addressLine1,
    place,
    affiliationNumber,
    gstin,
    email,
    phoneCountryCode,
    phoneNumber,
    telephone,
    addressLine2,
    pincode,
  ];
}

sealed class InstitutionFormEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the form, and Try again after the lists could not be read.
final class InstitutionFormStarted extends InstitutionFormEvent {
  const new();
}

final class InstitutionBoardChosen extends InstitutionFormEvent {
  const new(this.board);

  final Board? board;

  @override
  List<Object?> get props => [board];
}

final class InstitutionCategoryToggled extends InstitutionFormEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class InstitutionCountryChosen extends InstitutionFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class InstitutionStateChosen extends InstitutionFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class InstitutionCityChosen extends InstitutionFormEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class InstitutionFormSubmitted extends InstitutionFormEvent {
  const new(this.texts);

  final InstitutionTexts texts;

  @override
  List<Object?> get props => [texts];
}

sealed class InstitutionFormState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class InstitutionFormLoading extends InstitutionFormState {
  const new();
}

/// The lists the form needs could not be read.
class InstitutionFormFailed extends InstitutionFormState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form: what is chosen, and the lists it is chosen from. [existing] is set when an Institution is edited.
/// A place the Institution already holds stays selected even when its entry has been hidden since and is no longer
/// listed, so saving does not drop it.
class InstitutionFormReady extends InstitutionFormState {
  const new({
    required this.categories,
    required this.countries,
    this.existing,
    this.states = const [],
    this.cities = const [],
    this.board,
    this.categoryIds = const [],
    this.countryId,
    this.stateId,
    this.cityId,
    this.saving = false,
    this.failure,
  });

  final Institution? existing;
  final List<MasterEntry> categories;
  final List<MasterEntry> countries;
  final List<MasterEntry> states;
  final List<MasterEntry> cities;
  final Board? board;
  final List<String> categoryIds;
  final String? countryId;
  final String? stateId;
  final String? cityId;
  final bool saving;

  /// The last save, or the last list that could not be read.
  final ApiFailure? failure;

  bool get isEdit => existing != null;

  InstitutionFormReady copyWith({
    List<MasterEntry>? states,
    List<MasterEntry>? cities,
    Board? Function()? board,
    List<String>? categoryIds,
    String? Function()? countryId,
    String? Function()? stateId,
    String? Function()? cityId,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => InstitutionFormReady(
    existing: existing,
    categories: categories,
    countries: countries,
    states: states ?? this.states,
    cities: cities ?? this.cities,
    board: board == null ? this.board : board(),
    categoryIds: categoryIds ?? this.categoryIds,
    countryId: countryId == null ? this.countryId : countryId(),
    stateId: stateId == null ? this.stateId : stateId(),
    cityId: cityId == null ? this.cityId : cityId(),
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    existing,
    categories,
    countries,
    states,
    cities,
    board,
    categoryIds,
    countryId,
    stateId,
    cityId,
    saving,
    failure,
  ];
}

class InstitutionFormSaved extends InstitutionFormState {
  const new(this.institution);

  final Institution institution;

  @override
  List<Object?> get props => [institution];
}

/// Adds an Institution (INS-02) or changes one (INS-04), picking its class categories and place from the masters.
class InstitutionFormBloc extends Bloc<InstitutionFormEvent, InstitutionFormState> {
  new(this._institutions, this._masters, {this.institutionId}) : super(const InstitutionFormLoading()) {
    on<InstitutionFormStarted>(_onStarted);
    on<InstitutionBoardChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(board: () => event.board))));
    on<InstitutionCategoryToggled>(_onCategoryToggled);
    on<InstitutionCountryChosen>(_onCountryChosen);
    on<InstitutionStateChosen>(_onStateChosen);
    on<InstitutionCityChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(cityId: () => event.id))));
    on<InstitutionFormSubmitted>(_onSubmitted);
  }

  final InstitutionsRepository _institutions;
  final MastersRepository _masters;

  /// Set to edit that Institution; null to add one.
  final String? institutionId;

  void _ready(void Function(InstitutionFormReady ready) work) {
    if (state case final InstitutionFormReady ready) work(ready);
  }

  Future<void> _onStarted(InstitutionFormStarted event, Emitter<InstitutionFormState> emit) async {
    emit(const InstitutionFormLoading());
    try {
      final existing = institutionId == null ? null : await _institutions.institution(institutionId!);
      final shown = await _masters.entries(MasterType.classCategories);
      final countries = await _masters.entries(MasterType.countries);
      // India is the only country for now: a new Institution starts there instead of asking.
      final countryId = existing != null ? existing.countryId : (countries.length == 1 ? countries.single.id : null);
      final states = countryId == null
          ? <MasterEntry>[]
          : await _masters.entries(MasterType.states, parentId: countryId);
      final stateId = existing?.stateId;
      final cities = stateId == null ? <MasterEntry>[] : await _masters.entries(MasterType.cities, parentId: stateId);
      emit(
        InstitutionFormReady(
          existing: existing,
          // A category the Institution already offers stays in the list after it was hidden, so it can be kept.
          categories: [
            ...shown,
            for (final offered in existing?.classesOffered ?? const <OfferedCategory>[])
              if (!shown.any((category) => category.id == offered.id)) MasterEntry(id: offered.id, name: offered.name),
          ],
          countries: countries,
          states: states,
          cities: cities,
          board: existing?.board,
          categoryIds: [for (final offered in existing?.classesOffered ?? const <OfferedCategory>[]) offered.id],
          countryId: countryId,
          stateId: stateId,
          cityId: existing?.cityId,
        ),
      );
    } on ApiFailure catch (failure) {
      emit(InstitutionFormFailed(failure));
    }
  }

  void _onCategoryToggled(InstitutionCategoryToggled event, Emitter<InstitutionFormState> emit) => _ready((ready) {
    final chosen = ready.categoryIds.contains(event.id);
    emit(
      ready.copyWith(
        categoryIds: chosen
            ? [
                for (final id in ready.categoryIds)
                  if (id != event.id) id,
              ]
            : [...ready.categoryIds, event.id],
      ),
    );
  });

  Future<void> _onCountryChosen(InstitutionCountryChosen event, Emitter<InstitutionFormState> emit) async {
    if (state case final InstitutionFormReady ready) {
      if (event.id == ready.countryId) return;
      // A state belongs to its country and a city to its state, so choosing another country empties both.
      final cleared = ready.copyWith(
        countryId: () => event.id,
        stateId: () => null,
        cityId: () => null,
        states: const [],
        cities: const [],
        failure: () => null,
      );
      emit(cleared);
      if (event.id == null) return;
      await _loadPlaces(emit, cleared, MasterType.states, event.id!);
    }
  }

  Future<void> _onStateChosen(InstitutionStateChosen event, Emitter<InstitutionFormState> emit) async {
    if (state case final InstitutionFormReady ready) {
      if (event.id == ready.stateId) return;
      final cleared = ready.copyWith(
        stateId: () => event.id,
        cityId: () => null,
        cities: const [],
        failure: () => null,
      );
      emit(cleared);
      if (event.id == null) return;
      await _loadPlaces(emit, cleared, MasterType.cities, event.id!);
    }
  }

  Future<void> _loadPlaces(
    Emitter<InstitutionFormState> emit,
    InstitutionFormReady from,
    MasterType type,
    String parentId,
  ) async {
    try {
      final entries = await _masters.entries(type, parentId: parentId);
      // The choice may have changed while the list was on its way; only the latest answer counts.
      if (state case final InstitutionFormReady now when _asked(now, type, parentId)) {
        emit(type == MasterType.states ? now.copyWith(states: entries) : now.copyWith(cities: entries));
      }
    } on ApiFailure catch (failure) {
      if (state case final InstitutionFormReady now when _asked(now, type, parentId)) {
        emit(now.copyWith(failure: () => failure));
      }
    }
  }

  bool _asked(InstitutionFormReady now, MasterType type, String parentId) =>
      parentId == (type == MasterType.states ? now.countryId : now.stateId);

  Future<void> _onSubmitted(InstitutionFormSubmitted event, Emitter<InstitutionFormState> emit) async {
    if (state case final InstitutionFormReady ready when !ready.saving) {
      emit(ready.copyWith(saving: true, failure: () => null));
      final draft = _draft(ready, event.texts);
      try {
        final saved = ready.existing == null
            ? await _institutions.create(draft)
            : await _institutions.update(ready.existing!.id, ready.existing!.version, draft);
        emit(InstitutionFormSaved(saved));
      } on ApiFailure catch (failure) {
        emit(ready.copyWith(failure: () => failure));
      }
    }
  }

  static String? _text(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  InstitutionDraft _draft(InstitutionFormReady ready, InstitutionTexts texts) {
    // The API takes the dial code without the plus and the number without spaces, which people type either way.
    final countryCode = _text(texts.phoneCountryCode.replaceAll(RegExp(r'[\s+]'), ''));
    final number = _text(texts.phoneNumber.replaceAll(RegExp(r'\s'), ''));
    return InstitutionDraft(
      name: texts.name.trim(),
      // An edit never sends the code; the draft carries the one it has.
      code: ready.existing?.code ?? texts.code.trim(),
      addressLine1: texts.addressLine1.trim(),
      classesOffered: ready.categoryIds,
      place: _text(texts.place),
      board: ready.board,
      affiliationNumber: _text(texts.affiliationNumber),
      gstin: _text(texts.gstin)?.toUpperCase(),
      email: _text(texts.email),
      // A country code alone is no number. A number without its code is sent as it is, so the API names the field.
      phone: number == null ? null : Phone(countryCode: countryCode ?? '', number: number),
      telephone: _text(texts.telephone),
      addressLine2: _text(texts.addressLine2),
      pincode: _text(texts.pincode),
      countryId: ready.countryId,
      stateId: ready.stateId,
      cityId: ready.cityId,
    );
  }
}
