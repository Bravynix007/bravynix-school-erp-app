import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/documents/domain/document.dart';
import 'package:bravynix_school_erp/features/documents/domain/documents_repository.dart';
import 'package:bravynix_school_erp/features/files/domain/file_opening.dart';
import 'package:bravynix_school_erp/features/files/domain/files_repository.dart';
import 'package:equatable/equatable.dart';

sealed class StaffDocumentsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the tab, and Try again after a failure.
final class StaffDocumentsStarted extends StaffDocumentsEvent {
  const new();
}

/// The title of the document being added changed.
final class StaffDocumentsTitleChanged extends StaffDocumentsEvent {
  const new(this.title);

  final String title;

  @override
  List<Object?> get props => [title];
}

/// The file of the document being added is uploaded and checked ([fileId]), or was taken away (null).
final class StaffDocumentsFileChosen extends StaffDocumentsEvent {
  const new(this.fileId);

  final String? fileId;

  @override
  List<Object?> get props => [fileId];
}

/// Attach the file chosen under the title.
final class StaffDocumentsAttached extends StaffDocumentsEvent {
  const new();
}

/// Take a document off the record.
final class StaffDocumentsRemoved extends StaffDocumentsEvent {
  const new(this.documentId);

  final String documentId;

  @override
  List<Object?> get props => [documentId];
}

/// Open the file of a document on the phone.
final class StaffDocumentsOpened extends StaffDocumentsEvent {
  const new(this.documentId);

  final String documentId;

  @override
  List<Object?> get props => [documentId];
}

sealed class StaffDocumentsState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffDocumentsLoading extends StaffDocumentsState {
  const new();
}

class StaffDocumentsFailed extends StaffDocumentsState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// A document that was attached or removed, for the screen to say so.
class StaffDocumentChange extends Equatable {
  const new(this.document, {required this.removed});

  final Document document;

  /// True when it was removed, false when it was attached.
  final bool removed;

  @override
  List<Object?> get props => [document, removed];
}

/// The documents, newest first, with the one being added: its [title] and the [fileId] of what was uploaded for it.
class StaffDocumentsReady extends StaffDocumentsState {
  const new({
    required this.documents,
    this.title = '',
    this.fileId,
    this.attaching = false,
    this.removing,
    this.opening,
    this.failure,
    this.phoneRefused = false,
    this.done,
  });

  final List<Document> documents;
  final String title;
  final String? fileId;

  /// The document is on its way to be attached.
  final bool attaching;

  /// The ID of the document on its way to be removed.
  final String? removing;

  /// The ID of the document whose link is on its way.
  final String? opening;

  /// The last attach, removal or link that was refused.
  final ApiFailure? failure;

  /// The phone had nothing to open the file with.
  final bool phoneRefused;

  /// The last document that was attached or removed.
  final StaffDocumentChange? done;

  bool get busy => attaching || removing != null || opening != null;

  bool get canAttach => title.trim().isNotEmpty && fileId != null && !busy;

  StaffDocumentsReady copyWith({
    List<Document>? documents,
    String? title,
    String? Function()? fileId,
    bool? attaching,
    String? Function()? removing,
    String? Function()? opening,
    ApiFailure? Function()? failure,
    bool? phoneRefused,
    StaffDocumentChange? Function()? done,
  }) => StaffDocumentsReady(
    documents: documents ?? this.documents,
    title: title ?? this.title,
    fileId: fileId == null ? this.fileId : fileId(),
    attaching: attaching ?? this.attaching,
    removing: removing == null ? this.removing : removing(),
    opening: opening == null ? this.opening : opening(),
    failure: failure == null ? this.failure : failure(),
    phoneRefused: phoneRefused ?? this.phoneRefused,
    done: done == null ? this.done : done(),
  );

  @override
  List<Object?> get props => [documents, title, fileId, attaching, removing, opening, failure, phoneRefused, done];
}

/// The documents kept with a staff member (STF-14, STF-15, DOC-03): the list, a way to add one from a file that was
/// uploaded, to take one off, and to open its file (FIL-03).
class StaffDocumentsBloc extends Bloc<StaffDocumentsEvent, StaffDocumentsState> {
  new(this._documents, this._files, this._opening, {required this.staffMemberId})
    : super(const StaffDocumentsLoading()) {
    on<StaffDocumentsStarted>(_onStarted);
    on<StaffDocumentsTitleChanged>((event, emit) => _ready((ready) => emit(ready.copyWith(title: event.title))));
    on<StaffDocumentsFileChosen>(
      (event, emit) => _ready((ready) => emit(ready.copyWith(fileId: () => event.fileId, failure: () => null))),
    );
    on<StaffDocumentsAttached>(_onAttached);
    on<StaffDocumentsRemoved>(_onRemoved);
    on<StaffDocumentsOpened>(_onOpened);
  }

  final DocumentsRepository _documents;
  final FilesRepository _files;
  final FileOpening _opening;
  final String staffMemberId;

  void _ready(void Function(StaffDocumentsReady ready) work) {
    if (state case final StaffDocumentsReady ready) work(ready);
  }

  Future<void> _onStarted(StaffDocumentsStarted event, Emitter<StaffDocumentsState> emit) async {
    emit(const StaffDocumentsLoading());
    try {
      emit(StaffDocumentsReady(documents: await _documents.staffDocuments(staffMemberId)));
    } on ApiFailure catch (failure) {
      emit(StaffDocumentsFailed(failure));
    }
  }

  Future<void> _onAttached(StaffDocumentsAttached event, Emitter<StaffDocumentsState> emit) async {
    if (state case final StaffDocumentsReady ready when ready.canAttach) {
      emit(ready.copyWith(attaching: true, failure: () => null, phoneRefused: false, done: () => null));
      try {
        final made = await _documents.attachToStaff(
          staffMemberId,
          title: ready.title.trim(),
          fileId: ready.fileId!,
        );
        _ready(
          (now) => emit(
            now.copyWith(
              documents: [made, ...now.documents],
              title: '',
              fileId: () => null,
              attaching: false,
              done: () => StaffDocumentChange(made, removed: false),
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(attaching: false, failure: () => failure)));
      }
    }
  }

  Future<void> _onRemoved(StaffDocumentsRemoved event, Emitter<StaffDocumentsState> emit) async {
    if (state case final StaffDocumentsReady ready when !ready.busy) {
      final removed = _find(ready, event.documentId);
      if (removed == null) return;
      emit(ready.copyWith(removing: () => removed.id, failure: () => null, phoneRefused: false, done: () => null));
      try {
        await _documents.deactivate(removed.id);
        _ready(
          (now) => emit(
            now.copyWith(
              documents: _without(now.documents, removed.id),
              removing: () => null,
              done: () => StaffDocumentChange(removed, removed: true),
            ),
          ),
        );
      } on ApiFailure catch (failure) {
        _ready(
          (now) => emit(
            now.copyWith(
              // Not found is the truth: it is already removed, or gone.
              documents: failure.code == 'NOT_FOUND' ? _without(now.documents, removed.id) : null,
              removing: () => null,
              failure: () => failure,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onOpened(StaffDocumentsOpened event, Emitter<StaffDocumentsState> emit) async {
    if (state case final StaffDocumentsReady ready when !ready.busy) {
      final document = _find(ready, event.documentId);
      if (document == null) return;
      emit(ready.copyWith(opening: () => document.id, failure: () => null, phoneRefused: false, done: () => null));
      try {
        final opened = await _opening.open(await _files.downloadLink(document.file.id));
        _ready((now) => emit(now.copyWith(opening: () => null, phoneRefused: !opened)));
      } on ApiFailure catch (failure) {
        _ready((now) => emit(now.copyWith(opening: () => null, failure: () => failure)));
      }
    }
  }

  static Document? _find(StaffDocumentsReady ready, String id) =>
      ready.documents.where((document) => document.id == id).firstOrNull;

  static List<Document> _without(List<Document> items, String id) => [
    for (final item in items)
      if (item.id != id) item,
  ];
}
