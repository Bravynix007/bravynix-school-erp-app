import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_repository.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The access tab of the staff profile (PRD 7.5): the subjects the person can teach (STF-08) and, for the Society Owner,
/// the other Institutions they may see (STF-10). Each list is saved on its own, and the profile behind learns of the
/// answer.
class StaffAccessTab extends StatelessWidget {
  const new({required this.member, required this.isOwner, super.key});

  final StaffMember member;

  /// Only the Society Owner changes the extra Institutions.
  final bool isOwner;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => StaffAccessBloc(
      getIt<StaffRepository>(),
      getIt<SubjectsRepository>(),
      getIt<InstitutionsRepository>(),
      member: member,
      canChangeInstitutions: isOwner,
    )..add(const StaffAccessStarted()),
    child: const StaffAccessView(),
  );
}

class StaffAccessView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<StaffAccessBloc, StaffAccessState>(
      // A saved list changes the staff member, which the profile behind keeps.
      listenWhen: (previous, current) =>
          previous is StaffAccessReady && current is StaffAccessReady && previous.member != current.member,
      listener: (context, state) {
        context.read<StaffProfileBloc>().add(StaffProfileMemberChanged((state as StaffAccessReady).member));
        AppSnackbar.show(context, message: l10n.staffAccessSaved, kind: AppSnackbarKind.success);
      },
      builder: (context, state) => switch (state) {
        StaffAccessLoading() => SkeletonCards(semanticLabel: l10n.loading, heights: const [160, 112]),
        StaffAccessFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
          key: const Key('staffAccess.forbidden'),
          title: staffErrorText(l10n, failure),
        ),
        StaffAccessFailed(:final failure) => StatePanel.error(
          key: const Key('staffAccess.failed'),
          title: staffErrorText(l10n, failure),
          actionLabel: l10n.retry,
          onAction: () => context.read<StaffAccessBloc>().add(const StaffAccessStarted()),
        ),
        StaffAccessReady() => _Lists(state: state),
      },
    );
  }
}

class _Lists extends StatelessWidget {
  const new({required this.state});

  final StaffAccessReady state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffAccessBloc>();
    String? errorFor(StaffAccessPart part) =>
        state.failedPart == part && state.failure != null ? staffErrorText(l10n, state.failure!) : null;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        _ChoiceSection(
          keyPrefix: 'staffAccess.subject',
          title: l10n.staffAccessSubjects,
          helper: l10n.staffAccessSubjectsHelper,
          empty: l10n.staffAccessSubjectsEmpty,
          choices: [for (final subject in state.subjects) (id: subject.id, name: subject.name)],
          ticked: state.subjectIds,
          canAdd: state.canAddSubject,
          onToggled: (id) => bloc.add(StaffSubjectToggled(id)),
          error: errorFor(StaffAccessPart.subjects),
          saveKey: const Key('staffAccess.saveSubjects'),
          saveLabel: l10n.staffAccessSaveSubjects,
          saving: state.saving == StaffAccessPart.subjects,
          onSave: state.saving == null && state.changed(StaffAccessPart.subjects)
              ? () => bloc.add(const StaffAccessSaved(StaffAccessPart.subjects))
              : null,
        ),
        if (bloc.canChangeInstitutions) ...[
          const SizedBox(height: AppSpacing.md),
          _ChoiceSection(
            keyPrefix: 'staffAccess.institution',
            title: l10n.staffAccessInstitutions,
            helper: l10n.staffAccessInstitutionsHelper,
            empty: l10n.staffAccessInstitutionsEmpty,
            choices: [for (final institution in state.institutions) (id: institution.id, name: institution.name)],
            ticked: state.institutionIds,
            canAdd: state.canAddInstitution,
            onToggled: (id) => bloc.add(StaffInstitutionToggled(id)),
            error: errorFor(StaffAccessPart.institutions),
            saveKey: const Key('staffAccess.saveInstitutions'),
            saveLabel: l10n.staffAccessSaveInstitutions,
            saving: state.saving == StaffAccessPart.institutions,
            onSave: state.saving == null && state.changed(StaffAccessPart.institutions)
                ? () => bloc.add(const StaffAccessSaved(StaffAccessPart.institutions))
                : null,
          ),
        ],
      ],
    );
  }
}

/// One list to tick from, with its own Save. An entry that is ticked but no longer offered (a subject or an
/// Institution deactivated since) stays in the list, so it can be kept or taken off (DDD 10.5).
class _ChoiceSection extends StatelessWidget {
  const new({
    required this.keyPrefix,
    required this.title,
    required this.helper,
    required this.empty,
    required this.choices,
    required this.ticked,
    required this.canAdd,
    required this.onToggled,
    required this.error,
    required this.saveKey,
    required this.saveLabel,
    required this.saving,
    required this.onSave,
  });

  final String keyPrefix;
  final String title;
  final String helper;
  final String empty;
  final List<({String id, String name})> choices;
  final List<String> ticked;

  /// Another entry may still be ticked (the lists hold 50 at most).
  final bool canAdd;
  final ValueChanged<String> onToggled;
  final String? error;
  final Key saveKey;
  final String saveLabel;
  final bool saving;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final kept = [
      for (final id in ticked)
        if (!choices.any((choice) => choice.id == id)) id,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title),
        const SizedBox(height: AppSpacing.xxs),
        Text(helper, style: text.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: choices.isEmpty && kept.isEmpty
              ? Text(empty, key: Key('$keyPrefix.empty'), style: text.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final choice in choices)
                      AppCheckboxTile(
                        key: ValueKey('$keyPrefix.${choice.id}'),
                        title: choice.name,
                        value: ticked.contains(choice.id),
                        onChanged: ticked.contains(choice.id) || canAdd ? (_) => onToggled(choice.id) : null,
                      ),
                    for (final id in kept)
                      AppCheckboxTile(
                        key: ValueKey('$keyPrefix.$id'),
                        title: l10n.masterEntryKept,
                        value: true,
                        onChanged: (_) => onToggled(id),
                      ),
                  ],
                ),
        ),
        if (error case final message?) ...[
          const SizedBox(height: AppSpacing.xs),
          InlineMessage.error(message, key: Key('$keyPrefix.error')),
        ],
        const SizedBox(height: AppSpacing.xs),
        AppButton(key: saveKey, label: saveLabel, loading: saving, onPressed: onSave),
      ],
    );
  }
}
