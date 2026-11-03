import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/school_class.dart';

final class ClassDeactivated extends ListEvent {
  const new(this.schoolClass);

  final SchoolClass schoolClass;

  @override
  List<Object?> get props => [schoolClass];
}

/// The classes of one Institution (CLS-01) and deactivating one (CLS-05).
class ClassesBloc extends ListBloc<SchoolClass> {
  new(this._classes, this.institutionId) {
    on<ClassDeactivated>(
      (event, emit) =>
          change(emit, event.schoolClass, event.schoolClass.id, () => _classes.deactivate(event.schoolClass.id)),
    );
  }

  final ClassesRepository _classes;
  final String institutionId;

  @override
  Future<List<SchoolClass>> read() => _classes.classes(institutionId);
}
