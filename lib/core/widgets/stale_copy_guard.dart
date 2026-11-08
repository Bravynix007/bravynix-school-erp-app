import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps a form opened from a list. When a save was refused because the list holds an old copy ([stale]: 409
/// VERSION_CONFLICT, changed meanwhile, or 404, gone; see `ApiFailure.outdatesCopy`), every way out, the top bar,
/// Cancel and the system back, closes with `true` so the list reads again. Leave through [Navigator.maybePop] so each
/// way goes through here.
class StaleCopyGuard extends StatelessWidget {
  const new({required this.stale, required this.child, super.key});

  final bool stale;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: !stale,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.pop(true);
    },
    child: child,
  );
}
