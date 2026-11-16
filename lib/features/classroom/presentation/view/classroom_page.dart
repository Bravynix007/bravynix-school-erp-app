import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/paged_list_view.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/classroom/domain/classroom.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/bloc/classroom_bloc.dart';
import 'package:bravynix_school_erp/features/classroom/presentation/view/classroom_error_text.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Profile → My students: the students in the sections the teacher leads or teaches this year (STU-01), under the
/// Institution switcher.
class ClassroomPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.classroomTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => RepositoryProvider(
                // The rows name the sections the teacher has: read once.
                create: (_) => SectionOptionsSource(
                  years: getIt<AcademicYearsRepository>(),
                  classes: getIt<ClassesRepository>(),
                  sections: getIt<SectionsRepository>(),
                ),
                child: BlocProvider(
                  create: (context) =>
                      ClassroomBloc(getIt<ClassroomRepository>(), context.read<SectionOptionsSource>(), institution.id)
                        ..add(const PagedListRequested()),
                  child: const ClassroomView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ClassroomView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ClassroomBloc>();
    return PagedListView<ClassroomEntry>(
      bloc: bloc,
      keyPrefix: 'classroom',
      searchHint: l10n.classroomSearchHint,
      searchClearTooltip: l10n.studentsSearchClear,
      loadMoreLabel: l10n.studentsLoadMore,
      errorText: (failure) => classroomErrorText(l10n, failure),
      onRetry: () => bloc.add(const PagedListRequested()),
      empty: (context, query) => query.isEmpty
          ? StatePanel.empty(title: l10n.classroomEmptyTitle, message: l10n.classroomEmptyMessage)
          : StatePanel.empty(
              key: const Key('classroom.noMatch'),
              title: l10n.studentsNoMatchTitle(query),
              message: l10n.classroomNoMatchMessage,
            ),
      idOf: (entry) => entry.student.id,
      // Nothing changes from this list, so no card is ever busy or locked.
      itemBuilder: (context, entry, {required busy, required locked}) => _StudentCard(entry: entry),
      changedMessage: (entry) => entry.student.fullName,
    );
  }
}

class _StudentCard extends StatelessWidget {
  const new({required this.entry});

  final ClassroomEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final student = entry.student;
    return AppCard(
      key: ValueKey('classroom.${student.id}'),
      child: PersonListTile(
        name: student.fullName,
        subtitle: [?entry.placeName, l10n.studentsRoll(student.placement.rollNumber)].join(' · '),
        onTap: () => context.push(AppRoutes.classroomStudent(student.id)),
      ),
    );
  }
}
