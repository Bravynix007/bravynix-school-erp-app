import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';

final class SubjectDeactivated extends ListEvent {
  const new(this.subject);

  final Subject subject;

  @override
  List<Object?> get props => [subject];
}

/// The Society's subjects (SUB-01) and deactivating one (SUB-04).
class SubjectsBloc extends ListBloc<Subject> {
  new(this._subjects) {
    on<SubjectDeactivated>(
      (event, emit) => change(emit, event.subject, event.subject.id, () => _subjects.deactivate(event.subject.id)),
    );
  }

  final SubjectsRepository _subjects;

  @override
  Future<List<Subject>> read() => _subjects.subjects();
}
