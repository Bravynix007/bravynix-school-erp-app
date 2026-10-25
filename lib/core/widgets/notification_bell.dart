import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The bell in the top bar, with an unread badge ("9+" above nine, hidden at
/// zero). The tooltip is the spoken name; `unreadLabel` ("3 unread") is added
/// to it when there is something unread, so the badge is not colour or number
/// only. Both come from the screen, which knows the language.
class NotificationBell extends StatelessWidget {
  const new({
    required this.tooltip,
    required this.onPressed,
    this.count = 0,
    this.unreadLabel,
    this.onAccent = false,
    super.key,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final int count;
  final String? unreadLabel;

  /// White icon, for use on an accent header.
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final white = theme.colorScheme.onPrimary;
    final spoken = count > 0 && unreadLabel != null ? '$tooltip, $unreadLabel' : tooltip;
    final badge = count > 9 ? '9+' : '$count';
    return Semantics(
      container: true,
      button: true,
      label: spoken,
      onTap: onPressed,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        excludeFromSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(Icons.notifications_none, color: onAccent ? white : null),
              style: IconButton.styleFrom(minimumSize: const Size.square(AppSpacing.minTouchTarget)),
            ),
            if (count > 0)
              PositionedDirectional(
                top: AppSpacing.xxs,
                end: AppSpacing.xxs,
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: onAccent ? white : AppColors.surface, width: 1.5),
                    ),
                    child: Text(
                      badge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
