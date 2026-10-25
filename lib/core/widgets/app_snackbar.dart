import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// The kind of message in an [AppSnackbar].
enum AppSnackbarKind { info, success, error }

/// A short message at the foot of the screen after an action: "Attendance
/// saved", "Could not save. Try again". The icon and the words carry the kind,
/// never the colour alone.
///
/// A message with an action (Undo, Retry) and every error stays until the
/// person dismisses it or the next one replaces it, so a keyboard or switch
/// user is not timed out (WCAG 2.2.1); such a message therefore needs
/// `dismissLabel` ("Dismiss"). Other messages leave after 4 seconds, or by
/// swiping down. Material announces the text to screen readers when it appears.
///
/// The message always has the full width. The buttons sit under it, at the end,
/// and wrap if they do not fit side by side, so large text never squeezes the
/// words into a narrow column (Material's own action and close icon would).
abstract final class AppSnackbar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    AppSnackbarKind kind = AppSnackbarKind.info,
    String? actionLabel,
    VoidCallback? onAction,
    String? dismissLabel,
  }) {
    assert((actionLabel == null) == (onAction == null), 'Give both actionLabel and onAction, or neither');
    final persistent = actionLabel != null || kind == AppSnackbarKind.error;
    assert(
      !persistent || dismissLabel != null,
      'A message with an action, and every error, stays until dismissed, so it needs a dismiss label',
    );
    final icon = switch (kind) {
      AppSnackbarKind.info => Icons.info_outline,
      AppSnackbarKind.success => Icons.check_circle_outline,
      AppSnackbarKind.error => Icons.error_outline,
    };
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Icon(icon, size: 20, color: AppColors.surface),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(message)),
              ],
            ),
            if (actionLabel != null || dismissLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  children: [
                    if (actionLabel != null)
                      _SnackbarButton(
                        label: actionLabel,
                        onPressed: () {
                          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                          onAction!();
                        },
                      ),
                    if (dismissLabel != null)
                      _SnackbarButton(
                        label: dismissLabel,
                        onPressed: () => messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss),
                      ),
                  ],
                ),
              ),
          ],
        ),
        persist: persistent,
      ),
    );
  }
}

/// A text button on the dark snackbar: white text, and a white 2 px ring for
/// keyboard and switch focus (the ink ring would vanish on the ink background).
class _SnackbarButton extends StatelessWidget {
  const new({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style:
          TextButton.styleFrom(
            foregroundColor: AppColors.surface,
            minimumSize: const Size.square(48),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.focused) ? const BorderSide(color: AppColors.surface, width: 2) : null,
            ),
          ),
      child: Text(label),
    );
  }
}
