import 'package:bravynix_school_erp/app/di/injection.dart';
import 'package:bravynix_school_erp/app/router/app_routes.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/app_top_bar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/state_panel.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subject.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/bloc/subjects_bloc.dart';
import 'package:bravynix_school_erp/features/subjects/presentation/view/subject_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// School setup → Subjects: the Society's subjects, shared by all its Institutions (SUB-01). Owners and Institution
/// Admins reach School setup, and both may add, change and deactivate (API design 10.4i).
class SubjectsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SubjectsBloc(getIt<SubjectsRepository>())..add(const SubjectsRequested()),
    child: const SubjectsView(),
  );
}

class SubjectsView extends StatelessWidget {
  const new({super.key});

  /// A saved subject joins the list, so it is read again when the form closes with true.
  static Future<void> _openForm(BuildContext context, {Subject? subject}) async {
    final bloc = context.read<SubjectsBloc>();
    final saved = await context.push<bool>(AppRoutes.subjectForm, extra: subject);
    if (saved ?? false) bloc.add(const SubjectsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(title: l10n.subjectsTitle, onBack: () => context.pop(), backTooltip: l10n.back),
          Expanded(
            child: BlocConsumer<SubjectsBloc, SubjectsState>(
              listenWhen: (previous, current) => current is SubjectsLoaded && current.deactivated != null,
              listener: (context, state) {
                if (state is SubjectsLoaded) {
                  AppSnackbar.show(
                    context,
                    message: l10n.subjectDeactivated(state.deactivated!.name),
                    kind: AppSnackbarKind.success,
                  );
                }
              },
              builder: (context, state) => switch (state) {
                SubjectsLoading() => Semantics(
                  label: l10n.loading,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.screenMargin),
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [
                      SkeletonBox(height: 96, radius: AppRadius.card),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonBox(height: 96, radius: AppRadius.card),
                    ],
                  ),
                ),
                SubjectsFailed(:final failure) when failure.code == 'FORBIDDEN' => StatePanel.forbidden(
                  key: const Key('subjects.forbidden'),
                  title: subjectErrorText(l10n, failure),
                ),
                SubjectsFailed(:final failure) => StatePanel.error(
                  key: const Key('subjects.failed'),
                  title: subjectErrorText(l10n, failure),
                  actionLabel: l10n.retry,
                  onAction: () => context.read<SubjectsBloc>().add(const SubjectsRequested()),
                ),
                SubjectsLoaded(:final subjects) when subjects.isEmpty => StatePanel.empty(
                  title: l10n.subjectsEmptyTitle,
                  message: l10n.subjectsEmptyMessage,
                  actionLabel: l10n.subjectAdd,
                  onAction: () => _openForm(context),
                ),
                SubjectsLoaded() => ListView(
                  padding: const EdgeInsets.all(AppSpacing.screenMargin),
                  children: [
                    if (state.actionFailure case final failure?) ...[
                      InlineMessage.error(subjectErrorText(l10n, failure), key: const Key('subjects.actionFailed')),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppButton(
                      key: const Key('subjects.add'),
                      label: l10n.subjectAdd,
                      icon: Icons.add,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _openForm(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final subject in state.subjects) ...[
                      _SubjectCard(
                        subject: subject,
                        busy: state.busyId == subject.id,
                        onEdit: () => _openForm(context, subject: subject),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const new({required this.subject, required this.busy, required this.onEdit});

  final Subject subject;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      key: ValueKey('subject.${subject.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(subject.name, style: text.titleMedium),
          if (subject.code case final code?)
            Text(
              code,
              style: AppTextStyles.code.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                key: ValueKey('subject.edit.${subject.id}'),
                label: l10n.subjectEdit,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.medium,
                onPressed: busy ? null : onEdit,
              ),
              AppButton(
                key: ValueKey('subject.deactivate.${subject.id}'),
                label: l10n.subjectDeactivate,
                variant: AppButtonVariant.text,
                size: AppButtonSize.medium,
                loading: busy,
                onPressed: busy ? null : () => _confirmDeactivate(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SubjectsBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: l10n.subjectDeactivateTitle(subject.name),
      message: l10n.subjectDeactivateMessage,
      confirmLabel: l10n.subjectDeactivate,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (confirmed ?? false) bloc.add(SubjectDeactivated(subject));
  }
}
