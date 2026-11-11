import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_teaching_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/teaching_assignments/domain/teaching_assignment.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The teaching part of the access tab (ASG-01 to ASG-03): the sections and subjects the person teaches in an academic
/// year, with a way to give them one more from their own subjects, or to end one. Its bloc is provided with the others
/// above the tabs, so scrolling away or another tab does not read it again or lose a change on its way.
class StaffTeachingSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.staffTeachingTitle),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.staffTeachingHelper, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<StaffTeachingBloc, StaffTeachingState>(
          // What went through stays in the state until the next change starts, which clears it.
          listenWhen: (previous, current) =>
              current is StaffTeachingReady &&
              current.done != null &&
              (previous is! StaffTeachingReady || previous.done != current.done),
          listener: (context, state) {
            final change = (state as StaffTeachingReady).done!;
            AppSnackbar.show(
              context,
              message: change.ended
                  ? l10n.staffTeachingEnded(change.assignment.subjectName, change.assignment.sectionName)
                  : l10n.staffTeachingAssigned(change.assignment.subjectName, change.assignment.sectionName),
              kind: AppSnackbarKind.success,
            );
          },
          builder: (context, state) => switch (state) {
            // A box and not SkeletonCards, which is a list of its own: this part sits inside the one of the tab.
            StaffTeachingLoading() => Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const ExcludeSemantics(child: SkeletonBox(height: 160, radius: AppRadius.card)),
            ),
            StaffTeachingFailed(:final failure) => InlineMessage.error(
              staffTeachingErrorText(l10n, failure),
              key: const Key('staffTeaching.failed'),
              actionLabel: l10n.retry,
              onAction: () => context.read<StaffTeachingBloc>().add(const StaffTeachingStarted()),
            ),
            StaffTeachingReady() => _Ready(state: state),
          },
        ),
      ],
    );
  }
}

class _Ready extends StatelessWidget {
  const new({required this.state});

  final StaffTeachingReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final bloc = context.read<StaffTeachingBloc>();
    if (state.years.isEmpty) {
      return AppCard(
        child: Text(l10n.staffTeachingNoYears, key: const Key('staffTeaching.noYears'), style: text.bodyMedium),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasterDropdown(
          key: const Key('staffTeaching.year'),
          label: l10n.staffTeachingYear,
          entries: [for (final year in state.years) MasterEntry(id: year.id, name: year.name)],
          value: state.yearId,
          onChanged: state.busy ? null : (id) => bloc.add(StaffTeachingYearChosen(id!)),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.reading)
          Semantics(
            label: l10n.loading,
            liveRegion: true,
            child: const ExcludeSemantics(child: SkeletonBox(height: 96, radius: AppRadius.card)),
          )
        else
          _Assignments(state: state),
        // What was refused, either a new assignment or an end, whether or not there is a form to add one.
        if (state.failure case final failure?) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineMessage.error(staffTeachingErrorText(l10n, failure), key: const Key('staffTeaching.error')),
        ],
        const SizedBox(height: AppSpacing.sm),
        _Add(state: state),
      ],
    );
  }
}

class _Assignments extends StatelessWidget {
  const new({required this.state});

  final StaffTeachingReady state;

  Future<void> _confirmEnd(BuildContext context, TeachingAssignment assignment) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffTeachingBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.staffTeachingEndTitle(assignment.subjectName, assignment.sectionName),
      message: l10n.staffTeachingEndMessage,
      confirmLabel: l10n.staffTeachingEndAction,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(StaffTeachingEnded(assignment.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: state.assignments.isEmpty
          ? Text(l10n.staffTeachingNone, key: const Key('staffTeaching.none'), style: text.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, assignment) in state.assignments.indexed) ...[
                  if (index > 0) const Divider(height: AppSpacing.md * 2),
                  Text(assignment.subjectName, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(assignment.sectionName, style: text.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  AppButton(
                    key: Key('staffTeaching.end.${assignment.id}'),
                    label: l10n.staffTeachingEnd,
                    variant: AppButtonVariant.secondary,
                    loading: state.ending == assignment.id,
                    onPressed: state.busy ? null : () => _confirmEnd(context, assignment),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Add extends StatelessWidget {
  const new({required this.state});

  final StaffTeachingReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffTeachingBloc>();
    // Without a subject on their list, or a section to put them in, there is nothing to choose.
    final nothingToChoose = state.subjects.isEmpty
        ? l10n.staffTeachingNoSubjects
        : state.sections.isEmpty
        ? l10n.staffTeachingNoSections
        : null;
    if (nothingToChoose != null) {
      return AppCard(
        child: Text(
          nothingToChoose,
          key: const Key('staffTeaching.nothingToChoose'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    // The fields are not in a card: a dropdown has no room to spare at a large text size on a small phone.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasterDropdown(
          key: const Key('staffTeaching.section'),
          label: l10n.staffTeachingSection,
          entries: [for (final section in state.sections) MasterEntry(id: section.id, name: section.name)],
          value: state.sectionId,
          noneLabel: l10n.staffTeachingChoose,
          onChanged: state.busy ? null : (id) => bloc.add(StaffTeachingSectionChosen(id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        MasterDropdown(
          key: const Key('staffTeaching.subject'),
          label: l10n.staffTeachingSubject,
          entries: [for (final subject in state.subjects) MasterEntry(id: subject.id, name: subject.name)],
          value: state.subjectId,
          noneLabel: l10n.staffTeachingChoose,
          onChanged: state.busy ? null : (id) => bloc.add(StaffTeachingSubjectChosen(id)),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('staffTeaching.assign'),
          label: l10n.staffTeachingAssign,
          loading: state.adding,
          onPressed: state.canAdd ? () => bloc.add(const StaffTeachingAdded()) : null,
        ),
      ],
    );
  }
}
