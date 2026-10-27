import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Says that the active role is blocked, and who to ask. The reason is not sent to anyone but the Owner
/// (API design 6.5), who reads it from SOC-02 below. Shows nothing for a role that is not blocked.
class BlockedAccessNotice extends StatelessWidget {
  const new({required this.active, super.key});

  final AuthContext active;

  @override
  Widget build(BuildContext context) {
    if (!active.isBlocked) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final society = active.societyName ?? '';
    return switch (active.role) {
      RoleCode.superAdmin => const SizedBox.shrink(),
      RoleCode.societyOwner => InlineMessage.error(l10n.blockedOwnersNotice(society)),
      RoleCode.institutionAdmin || RoleCode.teacherStaff => InlineMessage.error(l10n.blockedStaffNotice(society)),
      RoleCode.studentParent => InlineMessage.error(l10n.blockedParentNotice),
    };
  }
}
