import 'dart:async';

import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  /// The control that was focused when the message appeared (usually the
  /// button that caused it). When a keyboard or switch user closes the message
  /// from one of its buttons, focus goes back there so they keep their place.
  /// It is null when nothing was focused (a touch user), so a tap never moves
  /// focus or opens the keyboard.
  static FocusNode? _returnTo;
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _current;

  /// Forgets the message and the focus to return to. For tests, which share these statics.
  @visibleForTesting
  static void debugReset() {
    _current = null;
    _returnTo = null;
  }

  static bool _focusIsOnSnackbar() =>
      FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<SnackBar>() != null;

  /// Closes the message on screen, if any. Used by Escape (see [SnackbarEscape]).
  static void _close() {
    final fromSnackbar = _focusIsOnSnackbar();
    _current?.close();
    if (fromSnackbar) _restoreFocus();
  }

  /// Once the message has left (it animates out first, and the button keeps
  /// focus until then), puts focus back where it was if it has been lost.
  static void _restoreFocus() {
    final leaving = _current;
    void restore() => WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _returnTo;
      final context = target?.context;
      if (target == null || context == null || !context.mounted) return;
      final focus = FocusManager.instance.primaryFocus;
      final lost = focus == null || focus is FocusScopeNode || focus.context == null;
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        // The action opened another page or a dialog. Focus belongs there; left alone, Flutter
        // would fall back to the control on the page underneath.
        final focusRoute = focus?.context == null ? null : ModalRoute.of(focus!.context!);
        if (lost || !(focusRoute?.isCurrent ?? true)) {
          Navigator.maybeOf(context)?.focusNode.enclosingScope?.requestFocus();
        }
        return;
      }
      if (lost && target.canRequestFocus) target.requestFocus();
    });
    if (leaving == null) {
      restore();
    } else {
      unawaited(leaving.closed.then((_) => restore()));
    }
  }

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
    // A message that replaces another keeps the control the first one remembered.
    if (!_focusIsOnSnackbar()) {
      final focus = FocusManager.instance.primaryFocus;
      _returnTo = focus == null || focus is FocusScopeNode ? null : focus;
    }
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
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
                          final fromSnackbar = _focusIsOnSnackbar();
                          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.action);
                          onAction!();
                          if (fromSnackbar) _restoreFocus();
                        },
                      ),
                    if (dismissLabel != null)
                      _SnackbarButton(
                        label: dismissLabel,
                        onPressed: () {
                          final fromSnackbar = _focusIsOnSnackbar();
                          messenger.hideCurrentSnackBar(reason: SnackBarClosedReason.dismiss);
                          if (fromSnackbar) _restoreFocus();
                        },
                      ),
                  ],
                ),
              ),
          ],
        ),
        persist: persistent,
      ),
    );
    _current = controller;
    unawaited(
      controller.closed.then((_) {
        if (identical(_current, controller)) _current = null;
      }),
    );
    return controller;
  }
}

/// Lets Escape close a message that stays on screen. A floating snackbar can
/// cover the control the person has just tabbed to, and WCAG 2.4.11 accepts
/// content that can be dismissed without moving focus. Put it once above the
/// pages (`MaterialApp.builder`).
///
/// It has its own shortcut instead of listening for `DismissIntent`, because
/// every `Scaffold` answers `DismissIntent` itself (for its drawer), and that
/// answer would always come first. With no message on screen, or while a dialog
/// or sheet is open, the key goes on to whoever else wants it.
class SnackbarEscape extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {SingleActivator(LogicalKeyboardKey.escape): _CloseSnackbarIntent()},
      child: Actions(
        actions: {_CloseSnackbarIntent: _CloseSnackbarAction()},
        child: child,
      ),
    );
  }
}

class _CloseSnackbarIntent extends Intent {
  const new();
}

class _CloseSnackbarAction extends Action<_CloseSnackbarIntent> {
  @override
  bool isEnabled(_CloseSnackbarIntent intent) {
    if (AppSnackbar._current == null) return false;
    // A dialog or sheet is a popup route; Escape belongs to it.
    final focus = FocusManager.instance.primaryFocus?.context;
    return focus == null || ModalRoute.of(focus) is! PopupRoute<Object?>;
  }

  @override
  Object? invoke(_CloseSnackbarIntent intent) {
    AppSnackbar._close();
    return null;
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
