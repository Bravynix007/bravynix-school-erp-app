import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/people/presentation/view/access_block_card.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The parent access card of the student profile: blocks the guardians' access to this child (STU-06) or lifts the
/// block (STU-07). The profile behind learns of the answer.
class StudentAccessSection extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.studentAccessTitle),
        const SizedBox(height: AppSpacing.xs),
        AccessBlockCard<StudentRecord>(
          keyPrefix: 'studentAccess',
          copy: AccessBlockCopy(
            statusActive: l10n.studentAccessActive,
            statusBlocked: l10n.studentAccessBlockedMessage,
            blockAction: l10n.studentBlockAction,
            unblockAction: l10n.studentUnblockAction,
            blockTitle: l10n.studentBlockTitle,
            blockMessage: l10n.studentBlockMessage,
            unblockTitle: l10n.studentUnblockTitle,
            unblockMessage: l10n.studentUnblockMessage,
            blockDone: l10n.studentBlockDone,
            unblockDone: l10n.studentUnblockDone,
          ),
          nameOf: (record) => record.fullName,
          errorText: (failure) => studentAccessErrorText(l10n, failure),
          onChanged: (context, record) => context.read<StudentProfileBloc>().add(StudentProfileRecordChanged(record)),
          // Deactivated meanwhile: the profile reads again and shows them so, without the card.
          onGone: (context) => context.read<StudentProfileBloc>().add(const StudentProfileRequested()),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
