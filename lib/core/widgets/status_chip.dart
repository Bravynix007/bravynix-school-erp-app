import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// What a status means. Each tone pairs a colour with its own icon, so the
/// meaning never rests on colour alone.
enum StatusTone {
  success(AppColors.success, AppColors.successBg, Icons.check_circle_outline),
  warning(AppColors.warning, AppColors.warningBg, Icons.warning_amber_outlined),
  error(AppColors.error, AppColors.errorBg, Icons.error_outline),
  info(AppColors.info, AppColors.infoBg, Icons.info_outline),
  neutral(AppColors.inkSecondary, AppColors.sunken, Icons.circle_outlined);

  new(this.foreground, this.background, this.icon);

  final Color foreground;
  final Color background;
  final IconData icon;
}

/// A small pill that states a status: Paid, Overdue, Present.
class StatusChip extends StatelessWidget {
  const new({required this.label, this.tone = StatusTone.neutral, this.showIcon = true, super.key});

  final String label;
  final StatusTone tone;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[Icon(tone.icon, size: 14, color: tone.foreground), const SizedBox(width: AppSpacing.xxs)],
            Flexible(
              child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: tone.foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
