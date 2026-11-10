import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/place_choice.dart';
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

final class InstitutionFormSubmitted extends InstitutionFormEvent {
  const new(this.texts, this.place);

  final InstitutionTexts texts;

  /// The place chosen in the address.
  final PlaceChoice place;

  @override
  List<Object?> get props => [texts, place];
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

/// The form: what is chosen, and the lists it is chosen from. [existing] is set when an Institution is edited. The
/// place of the address is chosen through its own `PlaceBloc`.
class InstitutionFormReady extends InstitutionFormState {
  const new({
    required this.categories,
    this.existing,
    this.board,
    this.categoryIds = const [],
    this.saving = false,
    this.failure,
  });

  final Institution? existing;
  final List<MasterEntry> categories;
  final Board? board;
  final List<String> categoryIds;
  final bool saving;

  /// The last save.
  final ApiFailure? failure;

  bool get isEdit => existing != null;

  InstitutionFormReady copyWith({
    Board? Function()? board,
    List<String>? categoryIds,
    bool? saving,
    ApiFailure? Function()? failure,
  }) => InstitutionFormReady(
    existing: existing,
    categories: categories,
    board: board == null ? this.board : board(),
    categoryIds: categoryIds ?? this.categoryIds,
    saving: saving ?? this.saving,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    existing,
    categories,
    board,
    categoryIds,
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

/// Adds an Institution (INS-02) or changes one (INS-04), picking its class categories from the masters.
class InstitutionFormBloc extends Bloc<InstitutionFormEvent, InstitutionFormState> {
  new(this._institutions, this._masters, {this.institutionId}) : super(const InstitutionFormLoading()) {
    on<InstitutionFormStarted>(_onStarted);
    on<InstitutionBoardChosen>((event, emit) => _ready((ready) => emit(ready.copyWith(board: () => event.board))));
    on<InstitutionCategoryToggled>(_onCategoryToggled);
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
      emit(
        InstitutionFormReady(
          existing: existing,
          // A category the Institution already offers stays in the list after it was hidden, so it can be kept.
          categories: [
            ...shown,
            for (final offered in existing?.classesOffered ?? const <OfferedCategory>[])
              if (!shown.any((category) => category.id == offered.id)) MasterEntry(id: offered.id, name: offered.name),
          ],
          board: existing?.board,
          categoryIds: [for (final offered in existing?.classesOffered ?? const <OfferedCategory>[]) offered.id],
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

  Future<void> _onSubmitted(InstitutionFormSubmitted event, Emitter<InstitutionFormState> emit) async {
    if (state case final InstitutionFormReady ready when !ready.saving) {
      emit(ready.copyWith(saving: true, failure: () => null));
      final draft = _draft(ready, event.texts, event.place);
      try {
        final saved = ready.existing == null
            ? await _institutions.create(draft)
            : await _institutions.update(ready.existing!.id, ready.existing!.version, draft);
        emit(InstitutionFormSaved(saved));
      } on ApiFailure catch (failure) {
        // A choice can be made while the save is out; keep what the form holds now, not what it held at the start.
        if (state case final InstitutionFormReady now) emit(now.copyWith(saving: false, failure: () => failure));
      }
    }
  }

  static String? _text(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  InstitutionDraft _draft(InstitutionFormReady ready, InstitutionTexts texts, PlaceChoice place) {
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
      // A country code alone is no number.
      phone: Phone.typed(texts.phoneCountryCode, texts.phoneNumber),
      telephone: _text(texts.telephone),
      addressLine2: _text(texts.addressLine2),
      pincode: _text(texts.pincode),
      countryId: place.countryId,
      stateId: place.stateId,
      cityId: place.cityId,
    );
  }
}
