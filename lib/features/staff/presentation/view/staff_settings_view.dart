import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/core/widgets/status_chip.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_block_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The settings tab of the staff profile (PRD 7.5): blocks the person's access to the app in this Society (STF-06) or
/// lifts the block (STF-07). The profile behind learns of the answer.
class StaffSettingsView extends StatelessWidget {
  const new({super.key});

  Future<void> _confirm(BuildContext context, StaffMember member) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StaffBlockBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: member.isBlocked ? l10n.staffUnblockTitle(member.fullName) : l10n.staffBlockTitle(member.fullName),
      message: member.isBlocked ? l10n.staffUnblockMessage : l10n.staffBlockMessage,
      confirmLabel: member.isBlocked ? l10n.staffUnblockAction : l10n.staffBlockAction,
      cancelLabel: l10n.cancel,
      destructive: !member.isBlocked,
    );
    if (confirmed ?? false) bloc.add(const StaffBlockToggled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<StaffBlockBloc, StaffBlockState>(
      // A block or a lift changes the staff member, which the profile behind keeps; so does a refusal that read the
      // record again because it was already as asked.
      listenWhen: (previous, current) => previous.member != current.member,
      listener: (context, state) {
        context.read<StaffProfileBloc>().add(StaffProfileMemberChanged(state.member));
        if (state is StaffBlockIdle) {
          AppSnackbar.show(
            context,
            message: state.member.isBlocked
                ? l10n.staffBlockDone(state.member.fullName)
                : l10n.staffUnblockDone(state.member.fullName),
            kind: AppSnackbarKind.success,
          );
        }
      },
      builder: (context, state) {
        final member = state.member;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          children: [
            SectionHeader(title: l10n.staffSettingsAccess),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (member.isBlocked) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusChip(label: l10n.staffBlocked, tone: StatusTone.error),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  Text(
                    member.isBlocked ? l10n.staffSettingsBlockedMessage : l10n.staffSettingsActive,
                    key: const Key('staffSettings.status'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (state case StaffBlockRefused(:final failure)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InlineMessage.error(
                      // An Institution Admin cannot stop a fellow Admin; only the Society Owner can.
                      failure.code == 'FORBIDDEN' ? l10n.errorStaffBlockForbidden : staffErrorText(l10n, failure),
                      key: const Key('staffSettings.error'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const Key('staffSettings.toggle'),
                    label: member.isBlocked ? l10n.staffUnblockAction : l10n.staffBlockAction,
                    variant: member.isBlocked ? AppButtonVariant.primary : AppButtonVariant.danger,
                    loading: state is StaffBlockWorking,
                    onPressed: () => _confirm(context, member),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
