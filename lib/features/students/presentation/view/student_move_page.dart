import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/optional_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/core/widgets/sticky_bottom_actions.dart';
import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:bravynix_school_erp/features/sections/domain/sections_repository.dart';
import 'package:bravynix_school_erp/features/students/domain/student.dart';
import 'package:bravynix_school_erp/features/students/domain/students_repository.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_move_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_warnings.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// What the form needs: the student as the list shows them, with the name of the place they sit in.
class StudentMoveArgs {
  const new(this.entry);

  final StudentListEntry entry;
}

/// What the snackbar says once a student's placement is changed: who, and a line for each second look the server asked
/// for.
String studentMovedMessage(AppLocalizations l10n, String name, List<String> warnings) =>
    [l10n.studentMoved(name), ...studentWarningLines(l10n, warnings)].join(' ');

/// School setup → Students → Move (STU-08). Closes with `true` once saved, so the list reads again.
class StudentMovePage extends StatelessWidget {
  const new({required this.args, super.key});

  final StudentMoveArgs args;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StudentMoveBloc(
      getIt<StudentsRepository>(),
      SectionOptionsSource(
        years: getIt<AcademicYearsRepository>(),
        classes: getIt<ClassesRepository>(),
        sections: getIt<SectionsRepository>(),
      ),
      args.entry.summary,
    )..add(const StudentMoveStarted()),
    child: StudentMoveView(entry: args.entry),
  );
}

class StudentMoveView extends StatelessWidget {
  const new({required this.entry, super.key});

  final StudentListEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<StudentMoveBloc, StudentMoveState>(
      listenWhen: (previous, current) => current is StudentMoveSaved,
      listener: (context, state) {
        if (state is StudentMoveSaved) {
          AppSnackbar.show(
            context,
            message: studentMovedMessage(l10n, entry.summary.fullName, state.warnings),
            kind: AppSnackbarKind.success,
          );
          context.pop(true);
        }
      },
      child: BlocBuilder<StudentMoveBloc, StudentMoveState>(
        builder: (context, state) => switch (state) {
          StudentMoveReady() => _Form(entry: entry, state: state),
          StudentMoveFailed(:final failure) when failure.code == 'FORBIDDEN' => _Frame(
            child: StatePanel.forbidden(
              key: const Key('studentMove.forbidden'),
              title: studentErrorText(l10n, failure),
            ),
          ),
          StudentMoveFailed(:final failure) => _Frame(
            child: StatePanel.error(
              key: const Key('studentMove.failed'),
              title: studentErrorText(l10n, failure),
              actionLabel: l10n.retry,
              onAction: () => context.read<StudentMoveBloc>().add(const StudentMoveStarted()),
            ),
          ),
          _ => _Frame(
            child: SkeletonCards(semanticLabel: l10n.loading, heights: const [120, 200]),
          ),
        },
      ),
    );
  }
}

/// The screen around a body that is not the form: a placeholder or a failed state.
class _Frame extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.studentMoveTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const new({required this.entry, required this.state});

  final StudentListEntry entry;
  final StudentMoveReady state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _rollNumber = TextEditingController(text: widget.entry.summary.placement.rollNumber);

  @override
  void dispose() {
    _rollNumber.dispose();
    super.dispose();
  }

  /// The fields the form shows an error under, named as the API names them.
  static const _fields = {'sectionId', 'rollNumber', 'effectiveDate'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StudentMoveBloc>();
    final state = widget.state;
    final summary = widget.entry.summary;
    final placement = summary.placement;
    final failure = state.failure;
    String? error(String field) => failure?.fieldError(field)?.message;
    final banner = failure != null && !failure.namesOnly(_fields) ? studentFormErrorText(l10n, failure) : null;
    final changed = state.sectionId != placement.sectionId || _rollNumber.text.trim() != placement.rollNumber;
    final today = DateTime.now();
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.studentMoveTitle, onBack: () => Navigator.maybePop(context), backTooltip: l10n.back),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                if (banner != null) ...[
                  InlineMessage.error(banner, key: const Key('studentMove.error')),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Text(summary.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  [
                    ?widget.entry.placeName,
                    l10n.studentsRoll(placement.rollNumber),
                    l10n.studentMoveSince(Formatters.schoolDate(placement.startDate)),
                  ].join(' · '),
                  key: const Key('studentMove.now'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MasterDropdown(
                        key: const Key('studentMove.section'),
                        label: l10n.studentSection,
                        entries: [for (final choice in state.sections) MasterEntry(id: choice.id, name: choice.name)],
                        value: state.sectionId,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('sectionId'),
                        onChanged: (id) => bloc.add(StudentMoveSectionChosen(id)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppTextField(
                        key: const Key('studentMove.rollNumber'),
                        label: l10n.studentRollNumber,
                        controller: _rollNumber,
                        mono: true,
                        required: true,
                        requiredLabel: l10n.fieldRequired,
                        error: error('rollNumber'),
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OptionalDateField(
                        key: const Key('studentMove.effectiveDate'),
                        label: l10n.studentMoveFrom,
                        day: state.effectiveDate,
                        hint: l10n.chooseDate,
                        clearLabel: l10n.clearDate(l10n.studentMoveFrom),
                        // Not before the placement began, and not after today.
                        firstDay: DateTime.tryParse(placement.startDate) ?? DateTime(2000),
                        lastDay: DateTime(today.year, today.month, today.day),
                        error: error('effectiveDate'),
                        onChanged: (day) => bloc.add(StudentMoveDateChosen(day)),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(l10n.studentMoveFromHelper, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: StickyBottomActions(
        primaryLabel: l10n.formSave,
        primaryLoading: state.saving,
        onPrimary: state.saving || !changed || _rollNumber.text.trim().isEmpty
            ? null
            : () => bloc.add(StudentMoveSubmitted(_rollNumber.text)),
        secondaryLabel: l10n.cancel,
        onSecondary: () => Navigator.maybePop(context),
      ),
    );
  }
}
