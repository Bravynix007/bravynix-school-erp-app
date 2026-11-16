import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student_import.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

sealed class StudentImportEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after the years could not be read.
final class StudentImportStarted extends StudentImportEvent {
  const new();
}

final class StudentImportYearChosen extends StudentImportEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// The file the upload field has had checked, or null when it was removed or replaced.
final class StudentImportFileChosen extends StudentImportEvent {
  const new(this.fileId);

  final String? fileId;

  @override
  List<Object?> get props => [fileId];
}

/// Show the sample file.
final class StudentImportSampleRequested extends StudentImportEvent {
  const new();
}

final class StudentImportSubmitted extends StudentImportEvent {
  const new();
}

/// Look again after the connection was lost while the import went on.
final class StudentImportChecked extends StudentImportEvent {
  const new();
}

sealed class StudentImportState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StudentImportLoading extends StudentImportState {
  const new();
}

/// The years could not be read.
class StudentImportFailed extends StudentImportState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The form: the year to add the students to, and the file that went up.
class StudentImportReady extends StudentImportState {
  const new({
    required this.years,
    this.yearId,
    this.fileId,
    this.sample,
    this.sampleLoading = false,
    this.sampleFailure,
    this.starting = false,
    this.failure,
  });

  final List<AcademicYear> years;
  final String? yearId;

  /// The ID of the import file the server calls Ready; null while none is.
  final String? fileId;

  /// The sample file, once it was asked for.
  final String? sample;
  final bool sampleLoading;
  final ApiFailure? sampleFailure;
  final bool starting;

  /// The last attempt to start that was refused.
  final ApiFailure? failure;

  bool get canStart => !starting && yearId != null && fileId != null;

  StudentImportReady copyWith({
    String? Function()? yearId,
    String? Function()? fileId,
    String? sample,
    bool? sampleLoading,
    ApiFailure? Function()? sampleFailure,
    bool? starting,
    ApiFailure? Function()? failure,
  }) => StudentImportReady(
    years: years,
    yearId: yearId == null ? this.yearId : yearId(),
    fileId: fileId == null ? this.fileId : fileId(),
    sample: sample ?? this.sample,
    sampleLoading: sampleLoading ?? this.sampleLoading,
    sampleFailure: sampleFailure == null ? this.sampleFailure : sampleFailure(),
    starting: starting ?? this.starting,
    failure: failure == null ? this.failure : failure(),
  );

  @override
  List<Object?> get props => [years, yearId, fileId, sample, sampleLoading, sampleFailure, starting, failure];
}

/// The import is queued or being read: [run] is the last answer, null before the first.
class StudentImportRunning extends StudentImportState {
  const new(this.importId, [this.run]);

  final String importId;
  final StudentImport? run;

  @override
  List<Object?> get props => [importId, run];
}

/// The connection was lost while the import went on: it carries on at the server, and Check again asks how far it is.
class StudentImportLost extends StudentImportState {
  const new(this.importId, this.failure, [this.run]);

  final String importId;
  final ApiFailure failure;
  final StudentImport? run;

  @override
  List<Object?> get props => [importId, failure, run];
}

/// The worker is finished, with rows imported or with a reason it read none.
class StudentImportFinished extends StudentImportState {
  const new(this.run);

  final StudentImport run;

  @override
  List<Object?> get props => [run];
}

/// Imports the students of a CSV file that went up (IMP-02) and follows the import until the worker has settled it
/// (IMP-03): every 2 seconds at first, as the server asks, then every 5. A repeat of the same attempt, after an answer
/// that was lost, carries the same Idempotency-Key, so it finds the first import.
class StudentImportBloc extends Bloc<StudentImportEvent, StudentImportState> {
  new(
    this._years,
    this._imports,
    this.institutionId, {
    String Function()? newKey,
    Future<void> Function(Duration)? pause,
  }) : _newKey = newKey ?? const Uuid().v4,
       _pause = pause ?? Future<void>.delayed,
       super(const StudentImportLoading()) {
    on<StudentImportStarted>(_onStarted);
    on<StudentImportYearChosen>((event, emit) => _change(emit, (ready) => ready.copyWith(yearId: () => event.id)));
    on<StudentImportFileChosen>((event, emit) => _change(emit, (ready) => ready.copyWith(fileId: () => event.fileId)));
    on<StudentImportSampleRequested>(_onSampleRequested);
    on<StudentImportSubmitted>(_onSubmitted);
    on<StudentImportChecked>(_onChecked);
  }

  final AcademicYearsRepository _years;
  final StudentImportsRepository _imports;
  final String institutionId;
  final String Function() _newKey;
  final Future<void> Function(Duration) _pause;

  static const _fast = Duration(seconds: 2);
  static const _slow = Duration(seconds: 5);

  /// How many looks come at the fast pace: 30 seconds of them.
  static const _fastLooks = 15;

  /// The key of the attempt that is on its way or was refused, kept so a repeat of it is the same attempt; null once
  /// the year or the file changes.
  String? _key;

  /// A choice changed by the person: made when nothing is on its way, and the attempt is a new one.
  void _change(Emitter<StudentImportState> emit, StudentImportReady Function(StudentImportReady ready) apply) {
    if (state case final StudentImportReady ready when !ready.starting) {
      _key = null;
      emit(apply(ready).copyWith(failure: () => null));
    }
  }

  Future<void> _onStarted(StudentImportStarted event, Emitter<StudentImportState> emit) async {
    emit(const StudentImportLoading());
    try {
      final years = await _years.years(institutionId);
      emit(StudentImportReady(years: years, yearId: years.where((year) => year.isCurrent).firstOrNull?.id));
    } on ApiFailure catch (failure) {
      emit(StudentImportFailed(failure));
    }
  }

  Future<void> _onSampleRequested(StudentImportSampleRequested event, Emitter<StudentImportState> emit) async {
    if (state case final StudentImportReady ready when !ready.sampleLoading) {
      emit(ready.copyWith(sampleLoading: true, sampleFailure: () => null));
      try {
        final sample = await _imports.template();
        if (state case final StudentImportReady now) emit(now.copyWith(sample: sample, sampleLoading: false));
      } on ApiFailure catch (failure) {
        if (state case final StudentImportReady now) {
          emit(now.copyWith(sampleLoading: false, sampleFailure: () => failure));
        }
      }
    }
  }

  Future<void> _onSubmitted(StudentImportSubmitted event, Emitter<StudentImportState> emit) async {
    if (state case final StudentImportReady ready when ready.canStart) {
      emit(ready.copyWith(starting: true, failure: () => null));
      final String importId;
      try {
        importId = await _imports.start(
          institutionId: institutionId,
          fileId: ready.fileId!,
          academicYearId: ready.yearId!,
          idempotencyKey: _key ??= _newKey(),
        );
      } on ApiFailure catch (failure) {
        if (state case final StudentImportReady now) emit(now.copyWith(starting: false, failure: () => failure));
        return;
      }
      emit(StudentImportRunning(importId));
      await _follow(importId, emit);
    }
  }

  Future<void> _onChecked(StudentImportChecked event, Emitter<StudentImportState> emit) async {
    if (state case final StudentImportLost lost) {
      emit(StudentImportRunning(lost.importId, lost.run));
      await _follow(lost.importId, emit, lost.run);
    }
  }

  /// Asks how the import is until it is settled, the screen goes, or the connection fails. `last` is the last answer
  /// there was (null before the first), which a failed look keeps.
  Future<void> _follow(String importId, Emitter<StudentImportState> emit, [StudentImport? last]) async {
    var run = last;
    for (var looks = 0; !emit.isDone; looks++) {
      try {
        run = await _imports.status(importId);
      } on ApiFailure catch (failure) {
        if (!emit.isDone) emit(StudentImportLost(importId, failure, run));
        return;
      }
      if (emit.isDone) return;
      if (run.status.isSettled) {
        emit(StudentImportFinished(run));
        return;
      }
      emit(StudentImportRunning(importId, run));
      await _pause(looks < _fastLooks ? _fast : _slow);
    }
  }
}
