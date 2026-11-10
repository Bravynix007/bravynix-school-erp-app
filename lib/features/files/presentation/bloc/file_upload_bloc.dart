import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/files/domain/chosen_file.dart';
import 'package:bravynix_school_erp/features/files/domain/file_check.dart';
import 'package:bravynix_school_erp/features/files/domain/file_purpose.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/uploaded_file.dart';
import 'package:equatable/equatable.dart';

sealed class FileUploadEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The person chose [file]; it is checked and sent.
final class FileUploadStarted extends FileUploadEvent {
  const new(this.file);

  final ChosenFile file;

  @override
  List<Object?> get props => [file];
}

/// Send the file again after a failure, with a new ticket.
final class FileUploadRetried extends FileUploadEvent {
  const new();
}

/// Forget the file, sent or not, so the field is empty again.
final class FileUploadCleared extends FileUploadEvent {
  const new();
}

final class _FileUploadProgressed extends FileUploadEvent {
  const new(this.sent);

  final double sent;

  @override
  List<Object?> get props => [sent];
}

sealed class FileUploadState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Nothing chosen.
final class FileUploadIdle extends FileUploadState {
  const new();
}

/// [file] is going to the store; [sent] is how much, from 0 to 1.
final class FileUploadSending extends FileUploadState {
  const new(this.file, {this.sent = 0});

  final ChosenFile file;
  final double sent;

  @override
  List<Object?> get props => [file, sent];
}

/// The server has checked the file: [uploaded] carries the ID for the form.
final class FileUploadDone extends FileUploadState {
  const new(this.file, this.uploaded);

  final ChosenFile file;
  final UploadedFile uploaded;

  @override
  List<Object?> get props => [file, uploaded];
}

/// The file could not be used: [problem] when the app refused it before sending, [failure] when the server or the
/// network did. Exactly one is set. A refused file cannot be retried, only replaced.
final class FileUploadFailed extends FileUploadState {
  const new(this.file, {this.problem, this.failure}) : assert((problem == null) != (failure == null), 'One reason');

  final ChosenFile file;
  final FileProblem? problem;
  final ApiFailure? failure;

  bool get canRetry => failure != null;

  @override
  List<Object?> get props => [file, problem, failure];
}

/// One file going from the phone to the server for [purpose] (API design 15.1): checked, sent with progress, and
/// confirmed. The form reads the ID from [FileUploadDone]. Choosing another file while one is going is ignored.
class FileUploadBloc extends Bloc<FileUploadEvent, FileUploadState> {
  new(this._files, {required this.purpose, required this.institutionId}) : super(const FileUploadIdle()) {
    on<FileUploadStarted>((event, emit) => _send(event.file, emit));
    on<FileUploadRetried>(_onRetried);
    on<FileUploadCleared>(_onCleared);
    on<_FileUploadProgressed>(_onProgressed);
  }

  final FilesRepository _files;
  final FilePurpose purpose;
  final String institutionId;

  Future<void> _onRetried(FileUploadRetried event, Emitter<FileUploadState> emit) async {
    if (state case final FileUploadFailed failed when failed.canRetry) await _send(failed.file, emit);
  }

  void _onCleared(FileUploadCleared event, Emitter<FileUploadState> emit) {
    if (state is! FileUploadSending) emit(const FileUploadIdle());
  }

  void _onProgressed(_FileUploadProgressed event, Emitter<FileUploadState> emit) {
    if (state case final FileUploadSending sending) emit(FileUploadSending(sending.file, sent: event.sent));
  }

  Future<void> _send(ChosenFile file, Emitter<FileUploadState> emit) async {
    if (state is FileUploadSending) return;
    final problem = checkFile(file, purpose);
    if (problem != null) {
      emit(FileUploadFailed(file, problem: problem));
      return;
    }
    emit(FileUploadSending(file));
    try {
      final uploaded = await _files.upload(
        file,
        purpose: purpose,
        institutionId: institutionId,
        onProgress: (sent) => add(_FileUploadProgressed(sent)),
      );
      emit(FileUploadDone(file, uploaded));
    } on ApiFailure catch (failure) {
      emit(FileUploadFailed(file, failure: failure));
    }
  }
}
