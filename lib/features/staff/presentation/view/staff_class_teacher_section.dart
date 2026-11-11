import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/presentation/view/master_dropdown.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_class_teacher_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The class teacher part of the access tab (STF-09): the section the person leads in an academic year of their home
/// Institution, chosen from its sections and saved on its own.
class StaffClassTeacherSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.staffClassTeacherTitle),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.staffClassTeacherHelper, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<StaffClassTeacherBloc, StaffClassTeacherState>(
          listenWhen: (previous, current) =>
              previous is StaffClassTeacherReady &&
              current is StaffClassTeacherReady &&
              previous.saving &&
              !current.saving &&
              current.failure == null,
          listener: (context, state) =>
              AppSnackbar.show(context, message: l10n.staffClassTeacherSaved, kind: AppSnackbarKind.success),
          builder: (context, state) => switch (state) {
            // A box and not SkeletonCards, which is a list of its own: this part sits inside the one of the tab.
            StaffClassTeacherLoading() => Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const ExcludeSemantics(child: SkeletonBox(height: 160, radius: AppRadius.card)),
            ),
            StaffClassTeacherFailed(:final failure) => InlineMessage.error(
              staffClassTeacherErrorText(l10n, failure),
              key: const Key('staffClassTeacher.failed'),
              actionLabel: l10n.retry,
              onAction: () => context.read<StaffClassTeacherBloc>().add(const StaffClassTeacherStarted()),
            ),
            StaffClassTeacherReady() => _Form(state: state),
          },
        ),
      ],
    );
  }
}

class _Form extends StatelessWidget {
  const new({required this.state});

  final StaffClassTeacherReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffClassTeacherBloc>();
    if (state.years.isEmpty) {
      return AppCard(
        child: Text(
          l10n.staffClassTeacherNoYears,
          key: const Key('staffClassTeacher.empty'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    // The fields are not in a card: a dropdown has no room to spare at a large text size on a small phone.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MasterDropdown(
          key: const Key('staffClassTeacher.year'),
          label: l10n.staffClassTeacherYear,
          entries: [for (final year in state.years) MasterEntry(id: year.id, name: year.name)],
          value: state.yearId,
          onChanged: state.saving ? null : (id) => bloc.add(StaffClassTeacherYearChosen(id!)),
        ),
        const SizedBox(height: AppSpacing.sm),
        MasterDropdown(
          key: const Key('staffClassTeacher.section'),
          label: l10n.staffClassTeacherSection,
          entries: [for (final section in state.sections) MasterEntry(id: section.id, name: section.name)],
          value: state.sectionId,
          noneLabel: l10n.staffClassTeacherNone,
          onChanged: state.saving ? null : (id) => bloc.add(StaffClassTeacherSectionChosen(id)),
        ),
        if (state.failure case final failure?) ...[
          const SizedBox(height: AppSpacing.sm),
          InlineMessage.error(staffClassTeacherErrorText(l10n, failure), key: const Key('staffClassTeacher.error')),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          key: const Key('staffClassTeacher.save'),
          label: l10n.staffClassTeacherSave,
          loading: state.saving,
          onPressed: !state.saving && state.changed ? () => bloc.add(const StaffClassTeacherSaved()) : null,
        ),
      ],
    );
  }
}
