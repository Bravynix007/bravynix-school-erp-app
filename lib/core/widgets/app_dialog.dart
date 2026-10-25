import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// Asks the user to confirm. Resolves to true on confirm, false on cancel and
/// null when dismissed. `destructive` makes the confirm button red, for
/// deletes and anything that cannot be undone. An `icon` is drawn in a tinted
/// circle above the title. The body scrolls, so a long translated message
/// or large text is never clipped.
Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
  IconData? icon,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      icon: icon == null ? null : _DialogIcon(icon: icon, destructive: destructive),
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

class _DialogIcon extends StatelessWidget {
  const new({required this.icon, required this.destructive});

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Center(
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: destructive ? AppColors.errorBg : scheme.primaryContainer,
          ),
          child: SizedBox.square(
            dimension: 64,
            child: Icon(icon, size: 28, color: destructive ? AppColors.error : scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}
