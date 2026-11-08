import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/sections/domain/section.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';

final class SectionDeactivated extends ListEvent {
  const new(this.section);

  final Section section;

  @override
  List<Object?> get props => [section];
}

/// The sections of one class (SEC-01) and deactivating one (SEC-04).
class SectionsBloc extends ListBloc<Section> {
  new(this._sections, this.classId) {
    on<SectionDeactivated>(
      (event, emit) => change(emit, event.section, event.section.id, () => _sections.deactivate(event.section.id)),
    );
  }

  final SectionsRepository _sections;
  final String classId;

  @override
  Future<List<Section>> read() => _sections.sections(classId);
}
