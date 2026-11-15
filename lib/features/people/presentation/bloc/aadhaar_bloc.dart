import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:equatable/equatable.dart';

sealed class AadhaarEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Set the Aadhaar number, as typed.
final class AadhaarSaved extends AadhaarEvent {
  const new(this.aadhaar);

  final String aadhaar;

  @override
  List<Object?> get props => [aadhaar];
}

final class AadhaarCleared extends AadhaarEvent {
  const new();
}

/// Show the whole number, for a reason that is kept in the audit.
final class AadhaarRevealed extends AadhaarEvent {
  const new(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// The sheet that showed the number, or a refusal, is closed: forget both.
final class AadhaarHidden extends AadhaarEvent {
  const new();
}

/// What the person asked for.
enum AadhaarAction { save, clear, reveal }

sealed class AadhaarState extends Equatable {
  const new(this.masked);

  /// The Aadhaar number with all but the last four digits hidden; null when none is set.
  final String? masked;

  @override
  List<Object?> get props => [masked];
}

class AadhaarIdle extends AadhaarState {
  const new(super.masked, {this.elsewhere = false});

  /// True right after a number was saved that another Institution of the Society also holds (a transfer, not an error).
  final bool elsewhere;

  @override
  List<Object?> get props => [masked, elsewhere];
}

class AadhaarWorking extends AadhaarState {
  const new(super.masked, this.action);

  final AadhaarAction action;

  @override
  List<Object?> get props => [masked, action];
}

class AadhaarRefused extends AadhaarState {
  const new(super.masked, this.action, this.failure, {required this.inSheet});

  final AadhaarAction action;
  final ApiFailure failure;

  /// True when the sheet of the action is open and says the refusal itself; false when there is none, as for a clear,
  /// or it was closed while the call was on its way, so the card says it.
  final bool inSheet;

  @override
  List<Object?> get props => [masked, action, failure, inSheet];
}

/// The whole number, for as long as the sheet that shows it is open.
class AadhaarShown extends AadhaarState {
  const new(super.masked, this.value);

  final String value;

  @override
  List<Object?> get props => [masked, value];
}

/// What a save answers with: the number masked, or null after a clear, and whether another Institution of the Society
/// holds the number too.
typedef AadhaarKept = ({String? masked, bool elsewhere});

/// The Aadhaar number of one person (staff STF-11 and STF-12, student STU-10 and STU-11): seen masked, set, cleared,
/// and revealed in full for a reason. The calls are given to it, so one bloc serves each. The number is held only while
/// it is shown, and the API never sends it back after it is set.
class AadhaarBloc extends Bloc<AadhaarEvent, AadhaarState> {
  new({required this.save, required this.reveal, String? masked}) : super(AadhaarIdle(masked)) {
    on<AadhaarSaved>((event, emit) => _set(event.aadhaar, AadhaarAction.save, emit));
    on<AadhaarCleared>((event, emit) => _set(null, AadhaarAction.clear, emit));
    on<AadhaarRevealed>(_onRevealed);
    on<AadhaarHidden>(_onHidden);
  }

  /// Sets the number, or clears it when given null.
  final Future<AadhaarKept> Function(String? aadhaar) save;

  /// The whole number, for a reason.
  final Future<String> Function(String reason) reveal;

  bool get _free => state is! AadhaarWorking;

  /// The sheet of the action that is on its way was closed: what comes back is not kept for it.
  bool _closed = false;

  void _onHidden(AadhaarHidden event, Emitter<AadhaarState> emit) {
    if (state is AadhaarWorking) {
      _closed = true;
    } else if (state is AadhaarShown || state is AadhaarRefused) {
      emit(AadhaarIdle(state.masked));
    }
  }

  /// A refusal is said in the sheet unless there is none open: a clear has none.
  AadhaarRefused _refused(String? masked, AadhaarAction action, ApiFailure failure) =>
      AadhaarRefused(masked, action, failure, inSheet: !_closed && action != AadhaarAction.clear);

  Future<void> _set(String? aadhaar, AadhaarAction action, Emitter<AadhaarState> emit) async {
    if (!_free) return;
    _closed = false;
    emit(AadhaarWorking(state.masked, action));
    try {
      final kept = await save(aadhaar);
      emit(AadhaarIdle(kept.masked, elsewhere: kept.elsewhere));
    } on ApiFailure catch (failure) {
      emit(_refused(state.masked, action, failure));
    }
  }

  Future<void> _onRevealed(AadhaarRevealed event, Emitter<AadhaarState> emit) async {
    if (!_free) return;
    _closed = false;
    emit(AadhaarWorking(state.masked, AadhaarAction.reveal));
    try {
      final value = await reveal(event.reason);
      // The number is held only while it is shown: with the sheet gone, it is let go of.
      emit(_closed ? AadhaarIdle(state.masked) : AadhaarShown(state.masked, value));
    } on ApiFailure catch (failure) {
      emit(
        _refused(
          // No number is held: the screen was out of date.
          failure.code == 'NOT_SET' ? null : state.masked,
          AadhaarAction.reveal,
          failure,
        ),
      );
    }
  }
}
