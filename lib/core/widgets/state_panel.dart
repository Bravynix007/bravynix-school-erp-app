import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

/// A centred message for a screen with nothing to show: empty, error, offline,
/// not allowed (403) and someone-else-changed-this (409). The copy comes from
/// the screen, which knows the error code it is explaining.
class StatePanel extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppColors.inkSecondary,
    this.announce = false,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null), 'Give both actionLabel and onAction, or neither');

  const new empty({required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key})
    : this(
        key: key,
        icon: Icons.inbox_outlined,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  const new error({required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key})
    : this(
        key: key,
        icon: Icons.error_outline,
        iconColor: AppColors.error,
        announce: true,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  const new offline({required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key})
    : this(
        key: key,
        icon: Icons.wifi_off_outlined,
        announce: true,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  const new forbidden({required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key})
    : this(
        key: key,
        icon: Icons.lock_outline,
        iconColor: AppColors.warning,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  const new conflict({required String title, String? message, String? actionLabel, VoidCallback? onAction, Key? key})
    : this(
        key: key,
        icon: Icons.sync_problem_outlined,
        iconColor: AppColors.warning,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Read out when it appears (a failure the person did not ask to see).
  final bool announce;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: MediaQuery.textScalerOf(context).scale(14) / 14 > 1.3
            ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
            : const EdgeInsets.all(AppSpacing.xl),
        child: Semantics(
          container: true,
          liveRegion: announce,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 48, color: iconColor)),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message!,
                  style: text.bodyMedium?.copyWith(color: AppColors.inkSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: actionLabel!, onPressed: onAction, size: AppButtonSize.medium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
