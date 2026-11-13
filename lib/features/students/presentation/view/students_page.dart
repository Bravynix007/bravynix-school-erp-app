import 'dart:async';

import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/bloc/paged_list_bloc.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_filter_bar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/paged_list_view.dart';
import 'package:bravynix_school_erp/core/widgets/person_list_tile.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/institutions/presentation/view/institution_scope.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_filters_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/students_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_filter_sheet.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_form_page.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_leaving_sheet.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_move_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Students: the students of the chosen Institution (STU-01). Owners and Institution Admins reach School
/// setup, and both may deactivate (STU-05).
class StudentsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.studentsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: InstitutionScope(
              builder: (context, institution) => MultiRepositoryProvider(
                providers: [
                  // The list names the sections and the filters offer them: read once.
                  RepositoryProvider(
                    create: (_) => SectionOptionsSource(
                      years: getIt<AcademicYearsRepository>(),
                      classes: getIt<ClassesRepository>(),
                      sections: getIt<SectionsRepository>(),
                    ),
                  ),
                ],
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (context) => StudentsBloc(
                        getIt<StudentsRepository>(),
                        context.read<SectionOptionsSource>(),
                        institution.id,
                      )..add(const PagedListRequested()),
                    ),
                    BlocProvider(
                      create: (context) =>
                          StudentFiltersBloc(context.read<SectionOptionsSource>(), institution.id)
                            ..add(const StudentFiltersStarted()),
                    ),
                  ],
                  child: const StudentsView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the form that adds a student to this Institution; one saved joins the list, so it is read again when the form
/// closes with true.
Future<void> _openAddForm(BuildContext context) async {
  final bloc = context.read<StudentsBloc>();
  final saved = await context.push<bool>(AppRoutes.studentForm, extra: StudentFormArgs(bloc.institutionId));
  if (saved ?? false) bloc.add(const PagedListRequested());
}

/// Opens the form that moves a student; a change joins the list, so it is read again when the form closes with true.
Future<void> _openMoveForm(BuildContext context, StudentListEntry entry) async {
  final bloc = context.read<StudentsBloc>();
  final saved = await context.push<bool>(AppRoutes.studentMove, extra: StudentMoveArgs(entry));
  if (saved ?? false) bloc.add(const PagedListRequested());
}

/// The students of one Institution, under the switcher: a search box, the year, class and section filters, and the
/// pages read so far.
class StudentsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StudentsBloc>();
    return BlocListener<StudentFiltersBloc, StudentFiltersState>(
      listenWhen: (previous, current) =>
          current is StudentFiltersReady && (previous is! StudentFiltersReady || previous.filter != current.filter),
      listener: (context, state) {
        if (state is StudentFiltersReady) bloc.add(StudentsFiltered(state.filter));
      },
      child: PagedListView<StudentListEntry>(
        bloc: bloc,
        keyPrefix: 'students',
        searchHint: l10n.studentsSearchHint,
        searchClearTooltip: l10n.studentsSearchClear,
        loadMoreLabel: l10n.studentsLoadMore,
        errorText: (failure) => studentErrorText(l10n, failure),
        onRetry: () {
          bloc.add(const PagedListRequested());
          // The filters read the same options, so they try again with the list when they failed; a chosen filter stays.
          final filters = context.read<StudentFiltersBloc>();
          if (filters.state is StudentFiltersFailed) filters.add(const StudentFiltersStarted());
        },
        belowSearch: (context, {required idle}) => _Filters(enabled: idle),
        empty: (context, query) => _Empty(query: query),
        leading: (context, {required idle}) => [
          AppButton(
            key: const Key('students.add'),
            label: l10n.studentsAddTitle,
            icon: Icons.add,
            variant: AppButtonVariant.secondary,
            onPressed: idle ? () => _openAddForm(context) : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        idOf: (entry) => entry.summary.id,
        itemBuilder: (context, entry, {required busy, required locked}) =>
            _StudentCard(entry: entry, busy: busy, locked: locked),
        changedMessage: (entry) => l10n.studentsDeactivated(entry.summary.fullName),
      ),
    );
  }
}

/// What an empty list says: nothing at all yet, nothing for the search, or nothing for the filters.
class _Empty extends StatelessWidget {
  const new({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = switch (context.watch<StudentFiltersBloc>().state) {
      StudentFiltersReady(:final filter) => !filter.isEmpty,
      _ => false,
    };
    if (query.isNotEmpty) {
      return StatePanel.empty(
        key: const Key('students.noMatch'),
        title: l10n.studentsNoMatchTitle(query),
        message: l10n.studentsNoMatchMessage,
      );
    }
    if (filtered) {
      return StatePanel.empty(
        key: const Key('students.noFilterMatch'),
        title: l10n.studentsNoFilterMatchTitle,
        message: l10n.studentsNoFilterMatchMessage,
      );
    }
    return StatePanel.empty(
      title: l10n.studentsEmptyTitle,
      message: l10n.studentsEmptyMessage,
      actionLabel: l10n.studentsAddTitle,
      onAction: () => _openAddForm(context),
    );
  }
}

/// The year, class and section pills, which open a sheet of choices each. They wait for the options and while a
/// deactivation goes.
class _Filters extends StatelessWidget {
  const new({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StudentFiltersBloc>();
    return BlocBuilder<StudentFiltersBloc, StudentFiltersState>(
      builder: (context, state) {
        if (state is! StudentFiltersReady) return const SizedBox.shrink();
        final options = state.options;
        final filter = state.filter;
        String? nameOf(Iterable<({String id, String name})> choices, String? id) =>
            choices.where((choice) => choice.id == id).map((choice) => choice.name).firstOrNull;
        final years = [for (final year in options.years) (id: year.id, name: year.name)];
        final classes = [for (final schoolClass in options.classes) (id: schoolClass.id, name: schoolClass.name)];
        final sections = [for (final section in state.sections) (id: section.id, name: section.name)];
        Future<void> pick(
          String title,
          List<({String id, String name})> choices,
          String? selected,
          StudentFiltersEvent Function(String? id) event,
        ) async {
          final chosen = await showStudentFilterSheet(context, title: title, options: choices, selected: selected);
          if (chosen != null) bloc.add(event(chosen.id));
        }

        // The pills wait while a deactivation goes.
        VoidCallback opens(
          String title,
          List<({String id, String name})> choices,
          String? selected,
          StudentFiltersEvent Function(String? id) event,
        ) => () {
          if (enabled) unawaited(pick(title, choices, selected, event));
        };

        return AppFilterBar(
          clearLabel: l10n.studentsFiltersClear,
          pillHint: l10n.studentsFilterHint,
          onClear: enabled ? () => bloc.add(const StudentFiltersCleared()) : null,
          filters: [
            AppFilter(
              label: l10n.studentsFilterYear,
              value: nameOf(years, filter.academicYearId),
              onTap: opens(l10n.studentsFilterYear, years, filter.academicYearId, StudentFiltersYearChosen.new),
            ),
            AppFilter(
              label: l10n.studentsFilterClass,
              value: nameOf(classes, filter.classId),
              onTap: opens(l10n.studentsFilterClass, classes, filter.classId, StudentFiltersClassChosen.new),
            ),
            AppFilter(
              label: l10n.studentsFilterSection,
              value: nameOf(sections, filter.sectionId),
              onTap: opens(l10n.studentsFilterSection, sections, filter.sectionId, StudentFiltersSectionChosen.new),
            ),
          ],
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  const new({required this.entry, required this.busy, required this.locked});

  final StudentListEntry entry;

  /// A change to this student is on its way.
  final bool busy;

  /// A change to any student is on its way, so no card starts another.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = entry.summary;
    // With a year chosen a row shows where the student sat then, which a move would not change: only the placement
    // they hold now can be moved.
    final canMove = context.select<StudentFiltersBloc, bool>(
      (filters) => switch (filters.state) {
        StudentFiltersReady(:final filter) => filter.academicYearId == null,
        _ => true,
      },
    );
    final detail = [
      ?entry.placeName,
      l10n.studentsRoll(summary.placement.rollNumber),
      if (summary.admissionNo case final id?) l10n.studentsAdmissionId(id),
    ].join(' · ');
    return AppCard(
      key: ValueKey('students.${summary.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PersonListTile(
            name: summary.fullName,
            subtitle: detail,
            trailing: summary.isBlocked ? StatusChip(label: l10n.studentsBlocked, tone: StatusTone.error) : null,
            onTap: locked ? null : () => unawaited(context.push<void>(AppRoutes.student(summary.id))),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              if (canMove)
                AppButton(
                  key: ValueKey('students.move.${summary.id}'),
                  label: l10n.studentsMove,
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.medium,
                  onPressed: locked ? null : () => unawaited(_openMoveForm(context, entry)),
                ),
              AppButton(
                key: ValueKey('students.deactivate.${summary.id}'),
                label: l10n.studentsDeactivate,
                variant: AppButtonVariant.text,
                size: AppButtonSize.medium,
                loading: busy,
                onPressed: locked ? null : () => _confirmDeactivate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final bloc = context.read<StudentsBloc>();
    final reason = await showStudentLeavingSheet(context, name: entry.summary.fullName);
    if (reason != null) bloc.add(StudentDeactivated(entry, reason));
  }
}
