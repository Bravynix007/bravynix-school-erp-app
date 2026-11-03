import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// A full-width band with an icon and one sentence: the error, warning and
/// info states from the design (never colour alone). With [actionLabel] and
/// [onAction] it offers one way forward under the sentence, such as reading
/// the record again after a conflict.
class InlineMessage extends StatelessWidget {
  const new error(this.text, {this.actionLabel, this.onAction, this.actionKey, super.key})
    : _background = AppColors.errorBg,
      _foreground = AppColors.error,
      _icon = Icons.error_outline;

  const new info(this.text, {this.actionLabel, this.onAction, this.actionKey, super.key})
    : _background = AppColors.infoBg,
      _foreground = AppColors.info,
      _icon = Icons.info_outline;

  const new warning(this.text, {this.actionLabel, this.onAction, this.actionKey, super.key})
    : _background = AppColors.warningBg,
      _foreground = AppColors.warning,
      _icon = Icons.warning_amber_outlined;

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The key of the action's button, for tests and the screen that reads it.
  final Key? actionKey;
  final Color _background;
  final Color _foreground;
  final IconData _icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: _background, borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, size: 20, color: _foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
                    if (actionLabel != null && onAction != null)
                      AppButton(
                        key: actionKey,
                        label: actionLabel!,
                        variant: AppButtonVariant.text,
                        size: AppButtonSize.medium,
                        onPressed: onAction,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
