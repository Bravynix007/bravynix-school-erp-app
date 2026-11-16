import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievement.dart';
import 'package:bravynix_school_erp/features/achievements/domain/achievements_repository.dart';
import 'package:equatable/equatable.dart';

sealed class AchievementsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The section is shown, and Try again after a failure.
final class AchievementsStarted extends AchievementsEvent {
  const new();
}

final class AchievementsTierChosen extends AchievementsEvent {
  const new(this.tier);

  final StarTier tier;

  @override
  List<Object?> get props => [tier];
}

final class AchievementsDescriptionChanged extends AchievementsEvent {
  const new(this.description);

  final String description;

  @override
  List<Object?> get props => [description];
}

/// Give the star that is chosen and described.
final class AchievementsGiven extends AchievementsEvent {
  const new();
}

/// Take a star back.
final class AchievementsRemoved extends AchievementsEvent {
  const new(this.achievementId);

  final String achievementId;

  @override
  List<Object?> get props => [achievementId];
}

sealed class AchievementsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class AchievementsLoading extends AchievementsState {
  const new();
}

class AchievementsFailed extends AchievementsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The stars of the student, and the star being given: its [tier] and [description].
class AchievementsReady extends AchievementsState {
  const new({
    required this.stars,
    this.tier = StarTier.silver,
    this.description = '',
    this.giving = false,
    this.removing,
    this.failure,
  });

  final Stars stars;
  final StarTier tier;
  final String description;

  /// The star is on its way.
  final bool giving;

  /// The ID of the star on its way to be taken back.
  final String? removing;

  /// The last give or removal that was refused.
  final ApiFailure? failure;

  bool get busy => giving || removing != null;

  /// The API takes 1 to 500 characters (API design 10.5d).
  bool get canGive => !busy && description.trim().isNotEmpty;

  AchievementsReady copyWith({
    Stars? stars,
    StarTier? tier,
    String? description,
    bool? giving,
    String? Function()? removing,
    ApiFailure? Function()? failure,
  }) => AchievementsReady(
    stars: stars ?? this.stars,
    tier: tier ?? this.tier,
    description: description ?? this.description,
    giving: giving ?? this.giving,
    removing: removing == null ? this.removing : removing(),
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [
    stars,
    tier,
    description,
    giving,
    removing,
    failure,
  ];
}

/// The stars of one student (ACH-01), giving one (ACH-02) and taking one back (ACH-03). The list is read again after a
/// change, so the counts are the server's.
class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  new(this._achievements, this.studentId) : super(const AchievementsLoading()) {
    on<AchievementsStarted>(_onStarted);
    on<AchievementsTierChosen>(
      (event, emit) => _edit(emit, (ready) => ready.copyWith(tier: event.tier)),
    );
    on<AchievementsDescriptionChanged>(
      (event, emit) => _edit(
        emit,
        (ready) => ready.copyWith(description: event.description),
      ),
    );
    on<AchievementsGiven>(_onGiven);
    on<AchievementsRemoved>(_onRemoved);
  }

  final AchievementsRepository _achievements;
  final String studentId;

  void _edit(
    Emitter<AchievementsState> emit,
    AchievementsReady Function(AchievementsReady ready) apply,
  ) {
    if (state case final AchievementsReady ready when !ready.busy) {
      emit(apply(ready).copyWith(failure: () => null));
    }
  }

  Future<void> _onStarted(
    AchievementsStarted event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(const AchievementsLoading());
    try {
      emit(AchievementsReady(stars: await _achievements.stars(studentId)));
    } on ApiFailure catch (failure) {
      emit(AchievementsFailed(failure));
    }
  }

  Future<void> _onGiven(
    AchievementsGiven event,
    Emitter<AchievementsState> emit,
  ) async {
    if (state case final AchievementsReady ready when ready.canGive) {
      emit(ready.copyWith(giving: true, failure: () => null));
      try {
        await _achievements.give(
          studentId,
          tier: ready.tier,
          description: ready.description.trim(),
        );
      } on ApiFailure catch (failure) {
        emit(ready.copyWith(giving: false, failure: () => failure));
        return;
      }
      // The star is given: the form is empty again, and the list is the server's.
      await _reread(emit, ready.copyWith(giving: false, description: ''));
    }
  }

  Future<void> _onRemoved(
    AchievementsRemoved event,
    Emitter<AchievementsState> emit,
  ) async {
    if (state case final AchievementsReady ready when !ready.busy) {
      emit(
        ready.copyWith(
          removing: () => event.achievementId,
          failure: () => null,
        ),
      );
      try {
        await _achievements.remove(event.achievementId);
      } on ApiFailure catch (failure) {
        emit(ready.copyWith(removing: () => null, failure: () => failure));
        return;
      }
      await _reread(emit, ready.copyWith(removing: () => null));
    }
  }

  /// Reads the stars after a change that went through; if that read fails the change still stands, so the old list
  /// stays with the refusal.
  Future<void> _reread(
    Emitter<AchievementsState> emit,
    AchievementsReady after,
  ) async {
    try {
      emit(after.copyWith(stars: await _achievements.stars(studentId)));
    } on ApiFailure catch (failure) {
      emit(after.copyWith(failure: () => failure));
    }
  }
}
