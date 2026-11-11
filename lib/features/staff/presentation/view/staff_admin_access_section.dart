import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/skeleton.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_admin_access_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The Admin access part of the access tab, for the Society Owner (INS-08 to INS-10): at which of the Institutions the
/// person is at they are an Admin, and a way to make them one or to take that away. Its bloc is provided with the
/// others above the tabs, so scrolling away or another tab does not lose a change on its way.
class StaffAdminAccessView extends StatelessWidget {
  const new({required this.memberName, super.key});

  final String memberName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.staffAdminTitle),
        const SizedBox(height: AppSpacing.xxs),
        Text(l10n.staffAdminHelper, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        BlocConsumer<StaffAdminAccessBloc, StaffAdminAccessState>(
          // A change that went through is in the state until the next one starts, which clears it.
          listenWhen: (_, current) => current is StaffAdminAccessReady && current.done != null,
          listener: (context, state) {
            final ready = state as StaffAdminAccessReady;
            final change = ready.done!;
            final institution = ready.institutions.firstWhere((item) => item.id == change.institutionId).name;
            AppSnackbar.show(
              context,
              message: change.granted
                  ? l10n.staffAdminGranted(memberName, institution)
                  : l10n.staffAdminRevoked(memberName, institution),
              kind: AppSnackbarKind.success,
            );
          },
          builder: (context, state) => switch (state) {
            // A box and not SkeletonCards, which is a list of its own: this part sits inside the one of the tab.
            StaffAdminAccessLoading() => Semantics(
              label: l10n.loading,
              liveRegion: true,
              child: const ExcludeSemantics(child: SkeletonBox(height: 96, radius: AppRadius.card)),
            ),
            StaffAdminAccessFailed(:final failure) => InlineMessage.error(
              staffAdminErrorText(l10n, failure, granted: true),
              key: const Key('staffAdmin.failed'),
              actionLabel: l10n.retry,
              onAction: () => context.read<StaffAdminAccessBloc>().add(const StaffAdminAccessStarted()),
            ),
            StaffAdminAccessReady() => _Institutions(state: state, memberName: memberName),
          },
        ),
      ],
    );
  }
}

class _Institutions extends StatelessWidget {
  const new({required this.state, required this.memberName});

  final StaffAdminAccessReady state;
  final String memberName;

  Future<void> _confirm(BuildContext context, InstitutionSummary institution, {required bool grant}) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffAdminAccessBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: grant
          ? l10n.staffAdminGrantTitle(memberName, institution.name)
          : l10n.staffAdminRevokeTitle(memberName, institution.name),
      message: grant ? l10n.staffAdminGrantMessage : l10n.staffAdminRevokeMessage,
      confirmLabel: grant ? l10n.staffAdminGrantAction : l10n.staffAdminRevokeAction,
      cancelLabel: l10n.cancel,
      destructive: !grant,
    );
    if (confirmed ?? false) {
      bloc.add(grant ? StaffAdminGranted(institution.id) : StaffAdminRevoked(institution.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: state.institutions.isEmpty
          ? Text(l10n.staffAdminEmpty, key: const Key('staffAdmin.empty'), style: text.bodyMedium)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, institution) in state.institutions.indexed) ...[
                  if (index > 0) const Divider(height: AppSpacing.md * 2),
                  _row(context, institution),
                ],
              ],
            ),
    );
  }

  Widget _row(BuildContext context, InstitutionSummary institution) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final isAdmin = state.adminAt.contains(institution.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(institution.name, style: text.titleMedium),
        const SizedBox(height: AppSpacing.xxs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: isAdmin
              ? StatusChip(
                  key: Key('staffAdmin.isAdmin.${institution.id}'),
                  label: l10n.staffAdminIs,
                  tone: StatusTone.success,
                )
              : Text(l10n.staffAdminIsNot, style: text.bodySmall),
        ),
        if (state.failed case final failed? when failed.institutionId == institution.id && state.failure != null) ...[
          const SizedBox(height: AppSpacing.xs),
          InlineMessage.error(
            staffAdminErrorText(l10n, state.failure!, granted: failed.granted),
            key: Key('staffAdmin.error.${institution.id}'),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          key: Key('staffAdmin.toggle.${institution.id}'),
          label: isAdmin ? l10n.staffAdminRevokeAction : l10n.staffAdminGrantAction,
          variant: isAdmin ? AppButtonVariant.secondary : AppButtonVariant.primary,
          loading: state.working == institution.id,
          onPressed: state.working == null ? () => _confirm(context, institution, grant: !isAdmin) : null,
        ),
      ],
    );
  }
}
