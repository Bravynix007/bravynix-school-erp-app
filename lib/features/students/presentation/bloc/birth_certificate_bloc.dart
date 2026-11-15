import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:equatable/equatable.dart';

sealed class BirthCertificateEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Set the number, as typed.
final class BirthCertificateSaved extends BirthCertificateEvent {
  const new(this.number);

  final String number;

  @override
  List<Object?> get props => [number];
}

final class BirthCertificateCleared extends BirthCertificateEvent {
  const new();
}

/// The sheet that took the number, or a refusal, is closed: forget the refusal.
final class BirthCertificateHidden extends BirthCertificateEvent {
  const new();
}

/// What the person asked for.
enum BirthCertificateAction { save, clear }

sealed class BirthCertificateState extends Equatable {
  const new(this.number);

  /// The number as it is written on the certificate; null when none is set.
  final String? number;

  @override
  List<Object?> get props => [number];
}

class BirthCertificateIdle extends BirthCertificateState {
  const new(super.number);
}

class BirthCertificateWorking extends BirthCertificateState {
  const new(super.number, this.action);

  final BirthCertificateAction action;

  @override
  List<Object?> get props => [number, action];
}

class BirthCertificateRefused extends BirthCertificateState {
  const new(super.number, this.action, this.failure, {required this.inSheet});

  final BirthCertificateAction action;
  final ApiFailure failure;

  /// True when the sheet of the action is open and says the refusal itself; false when there is none, as for a clear,
  /// or it was closed while the call was on its way, so the card says it.
  final bool inSheet;

  @override
  List<Object?> get props => [number, action, failure, inSheet];
}

/// The birth certificate number of one student (STU-10): shown whole, set, and cleared. The Aadhaar number beside it
/// is kept by its own bloc.
class BirthCertificateBloc extends Bloc<BirthCertificateEvent, BirthCertificateState> {
  new(this._students, {required this.studentId, String? number}) : super(BirthCertificateIdle(number)) {
    on<BirthCertificateSaved>((event, emit) => _set(event.number, BirthCertificateAction.save, emit));
    on<BirthCertificateCleared>((event, emit) => _set(null, BirthCertificateAction.clear, emit));
    on<BirthCertificateHidden>(_onHidden);
  }

  final StudentsRepository _students;
  final String studentId;

  /// The sheet of the action that is on its way was closed: a refusal of it is not for the sheet.
  bool _closed = false;

  void _onHidden(BirthCertificateHidden event, Emitter<BirthCertificateState> emit) {
    if (state is BirthCertificateWorking) {
      _closed = true;
    } else if (state is BirthCertificateRefused) {
      emit(BirthCertificateIdle(state.number));
    }
  }

  Future<void> _set(String? number, BirthCertificateAction action, Emitter<BirthCertificateState> emit) async {
    if (state is BirthCertificateWorking) return;
    _closed = false;
    emit(BirthCertificateWorking(state.number, action));
    try {
      final saved = await _students.setBirthCertificate(studentId, number);
      emit(BirthCertificateIdle(saved.identity.birthCertificateNumber));
    } on ApiFailure catch (failure) {
      emit(
        BirthCertificateRefused(
          state.number,
          action,
          failure,
          inSheet: !_closed && action == BirthCertificateAction.save,
        ),
      );
    }
  }
}
