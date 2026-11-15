import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/app_dialog.dart';
import 'package:bravynix_school_erp/core/widgets/app_snackbar.dart';
import 'package:bravynix_school_erp/core/widgets/inline_message.dart';
import 'package:bravynix_school_erp/core/widgets/section_header.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_block_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_error_text.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The parent access card of the student profile: blocks the guardians' access to this child (STU-06) or lifts the block
/// (STU-07). The profile behind learns of the answer.
class StudentAccessSection extends StatelessWidget {
  const new({super.key});

  Future<void> _confirm(BuildContext context, StudentRecord record) async {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<StudentBlockBloc>();
    final confirmed = await showConfirmDialog(
      context: context,
      title: record.isBlocked ? l10n.studentUnblockTitle(record.fullName) : l10n.studentBlockTitle(record.fullName),
      message: record.isBlocked ? l10n.studentUnblockMessage : l10n.studentBlockMessage,
      confirmLabel: record.isBlocked ? l10n.studentUnblockAction : l10n.studentBlockAction,
      cancelLabel: l10n.cancel,
      destructive: !record.isBlocked,
    );
    if (confirmed ?? false) bloc.add(const StudentBlockToggled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<StudentBlockBloc, StudentBlockState>(
      // A block or a lift changes the student, which the profile behind keeps; so does a refusal that read the student
      // again because they were already as asked.
      listenWhen: (previous, current) => previous.record != current.record,
      listener: (context, state) {
        context.read<StudentProfileBloc>().add(StudentProfileRecordChanged(state.record));
        if (state is StudentBlockIdle) {
          AppSnackbar.show(
            context,
            message: state.record.isBlocked
                ? l10n.studentBlockDone(state.record.fullName)
                : l10n.studentUnblockDone(state.record.fullName),
            kind: AppSnackbarKind.success,
          );
        }
      },
      builder: (context, state) {
        final record = state.record;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l10n.studentAccessTitle),
            const SizedBox(height: AppSpacing.xs),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    record.isBlocked ? l10n.studentAccessBlockedMessage : l10n.studentAccessActive,
                    key: const Key('studentAccess.status'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (state case StudentBlockRefused(:final failure)) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InlineMessage.error(studentAccessErrorText(l10n, failure), key: const Key('studentAccess.error')),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const Key('studentAccess.toggle'),
                    label: record.isBlocked ? l10n.studentUnblockAction : l10n.studentBlockAction,
                    variant: record.isBlocked ? AppButtonVariant.primary : AppButtonVariant.danger,
                    loading: state is StudentBlockWorking,
                    onPressed: () => _confirm(context, record),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}
