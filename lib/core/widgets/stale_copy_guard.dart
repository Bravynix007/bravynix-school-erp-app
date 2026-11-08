import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps a form opened from a list. When a save was refused because the list holds an old copy of the record (409
/// VERSION_CONFLICT: changed meanwhile, or 404: gone), every way out, the top bar, Cancel and the system back, closes
/// with `true` so the list reads again. Leave through [Navigator.maybePop] so each way goes through here.
class StaleCopyGuard extends StatelessWidget {
  const new({required this.failure, required this.child, super.key});

  /// Why the last save was refused, or null.
  final ApiFailure? failure;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: !(failure?.outdatesCopy ?? false),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) context.pop(true);
    },
    child: child,
  );
}
