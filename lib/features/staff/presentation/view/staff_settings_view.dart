import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/access_block_card.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The settings tab of the staff profile (PRD 7.5): blocks the person's access to the app in this Society (STF-06) or
/// lifts the block (STF-07). The profile behind learns of the answer.
class StaffSettingsView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      children: [
        SectionHeader(title: l10n.staffSettingsAccess),
        const SizedBox(height: AppSpacing.xs),
        AccessBlockCard<StaffMember>(
          keyPrefix: 'staffSettings',
          blockedBadge: l10n.staffBlocked,
          copy: AccessBlockCopy(
            statusActive: l10n.staffSettingsActive,
            statusBlocked: l10n.staffSettingsBlockedMessage,
            blockAction: l10n.staffBlockAction,
            unblockAction: l10n.staffUnblockAction,
            blockTitle: l10n.staffBlockTitle,
            blockMessage: l10n.staffBlockMessage,
            unblockTitle: l10n.staffUnblockTitle,
            unblockMessage: l10n.staffUnblockMessage,
            blockDone: l10n.staffBlockDone,
            unblockDone: l10n.staffUnblockDone,
          ),
          nameOf: (member) => member.fullName,
          // An Institution Admin cannot stop a fellow Admin; only the Society Owner can.
          errorText: (failure) =>
              failure.code == 'FORBIDDEN' ? l10n.errorStaffBlockForbidden : staffErrorText(l10n, failure),
          onChanged: (context, member) => context.read<StaffProfileBloc>().add(StaffProfileMemberChanged(member)),
          onGone: (context) => context.read<StaffProfileBloc>().add(const StaffProfileRequested()),
        ),
      ],
    );
  }
}
