import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Asks the user to confirm. Resolves to true on confirm, false on cancel and
/// null when dismissed. `destructive` makes the confirm button red, for
/// deletes and anything that cannot be undone.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      title: Text(title, style: Theme.of(dialogContext).textTheme.headlineSmall),
      content: Text(message, style: Theme.of(dialogContext).textTheme.bodyMedium),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      actions: [
        AppButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          variant: AppButtonVariant.text,
          size: AppButtonSize.medium,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          variant: destructive ? AppButtonVariant.danger : AppButtonVariant.primary,
          size: AppButtonSize.medium,
        ),
      ],
    ),
  );
}
