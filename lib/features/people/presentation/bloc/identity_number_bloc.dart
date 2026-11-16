import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:equatable/equatable.dart';

sealed class IdentityNumberEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Set the number, as typed.
final class IdentityNumberSaved extends IdentityNumberEvent {
  const new(this.number);

  final String number;

  @override
  List<Object?> get props => [number];
}

final class IdentityNumberCleared extends IdentityNumberEvent {
  const new();
}

/// Show the whole number, for a reason that is kept in the audit.
final class IdentityNumberRevealed extends IdentityNumberEvent {
  const new(this.reason);

  final String reason;

  @override
  List<Object?> get props => [reason];
}

/// The sheet that showed the number, or a refusal, is closed: forget both.
final class IdentityNumberHidden extends IdentityNumberEvent {
  const new();
}

/// What the person asked for.
enum IdentityNumberAction { save, clear, reveal }

sealed class IdentityNumberState extends Equatable {
  const new(this.number);

  /// The number as the card shows it, the Aadhaar with all but the last four digits hidden; null when none is set.
  final String? number;

  @override
  List<Object?> get props => [number];
}

class IdentityNumberIdle extends IdentityNumberState {
  const new(super.number, {this.elsewhere = false});

  /// True right after a number was saved that another Institution of the Society also holds (a transfer, not an error).
  final bool elsewhere;

  @override
  List<Object?> get props => [number, elsewhere];
}

class IdentityNumberWorking extends IdentityNumberState {
  const new(super.number, this.action);

  final IdentityNumberAction action;

  @override
  List<Object?> get props => [number, action];
}

class IdentityNumberRefused extends IdentityNumberState {
  const new(super.number, this.action, this.failure, {required this.inSheet});

  final IdentityNumberAction action;
  final ApiFailure failure;

  /// True when the sheet of the action is open and says the refusal itself; false when there is none, as for a clear,
  /// or it was closed while the call was on its way, so the card says it.
  final bool inSheet;

  @override
  List<Object?> get props => [number, action, failure, inSheet];
}

/// The whole number, for as long as the sheet that shows it is open.
class IdentityNumberShown extends IdentityNumberState {
  const new(super.number, this.whole);

  final String whole;

  @override
  List<Object?> get props => [number, whole];
}

/// What a save answers with: the number as the card shows it, or null after a clear, and whether another Institution of
/// the Society holds the number too.
typedef IdentityNumberKept = ({String? number, bool elsewhere});

/// An identity number of one person: the Aadhaar number of staff (STF-11, STF-12) and of students (STU-10, STU-11), and
/// the birth certificate number of students. It is seen, set and cleared, and when [reveal] is given the whole number
/// is shown for a reason. The calls are given to it, so one bloc serves each. A number that is shown whole is held only
/// while it is shown, and the API never sends the Aadhaar back after it is set.
class IdentityNumberBloc extends Bloc<IdentityNumberEvent, IdentityNumberState> {
  new({required this.save, this.reveal, String? number}) : super(IdentityNumberIdle(number)) {
    on<IdentityNumberSaved>((event, emit) => _set(event.number, IdentityNumberAction.save, emit));
    on<IdentityNumberCleared>((event, emit) => _set(null, IdentityNumberAction.clear, emit));
    on<IdentityNumberRevealed>(_onRevealed);
    on<IdentityNumberHidden>(_onHidden);
  }

  /// Sets the number, or clears it when given null.
  final Future<IdentityNumberKept> Function(String? number) save;

  /// The whole number, for a reason; null for a number that is shown whole already.
  final Future<String> Function(String reason)? reveal;

  bool get _free => state is! IdentityNumberWorking;

  /// The sheet of the action that is on its way was closed: what comes back is not kept for it.
  bool _closed = false;

  void _onHidden(IdentityNumberHidden event, Emitter<IdentityNumberState> emit) {
    if (state is IdentityNumberWorking) {
      _closed = true;
    } else if (state is IdentityNumberShown || state is IdentityNumberRefused) {
      emit(IdentityNumberIdle(state.number));
    }
  }

  /// A refusal is said in the sheet unless there is none open: a clear has none.
  IdentityNumberRefused _refused(String? number, IdentityNumberAction action, ApiFailure failure) =>
      IdentityNumberRefused(number, action, failure, inSheet: !_closed && action != IdentityNumberAction.clear);

  Future<void> _set(String? number, IdentityNumberAction action, Emitter<IdentityNumberState> emit) async {
    if (!_free) return;
    _closed = false;
    emit(IdentityNumberWorking(state.number, action));
    try {
      final kept = await save(number);
      emit(IdentityNumberIdle(kept.number, elsewhere: kept.elsewhere));
    } on ApiFailure catch (failure) {
      emit(_refused(state.number, action, failure));
    }
  }

  Future<void> _onRevealed(IdentityNumberRevealed event, Emitter<IdentityNumberState> emit) async {
    final reveal = this.reveal;
    if (reveal == null || !_free) return;
    _closed = false;
    emit(IdentityNumberWorking(state.number, IdentityNumberAction.reveal));
    try {
      final whole = await reveal(event.reason);
      // The number is held only while it is shown: with the sheet gone, it is let go of.
      emit(_closed ? IdentityNumberIdle(state.number) : IdentityNumberShown(state.number, whole));
    } on ApiFailure catch (failure) {
      emit(
        _refused(
          // No number is held: the screen was out of date.
          failure.code == 'NOT_SET' ? null : state.number,
          IdentityNumberAction.reveal,
          failure,
        ),
      );
    }
  }
}
