import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Opens a modal sheet with a drag handle, a title and a scrolling body. It
/// rises above the keyboard and never taller than the screen, so a form in it
/// stays reachable at large text sizes.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: isDismissible,
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    builder: (sheetContext) => PopScope(
      canPop: isDismissible,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                isDismissible ? 0 : AppSpacing.md,
                AppSpacing.screenMargin,
                0,
              ),
              child: Semantics(
                header: true,
                child: Text(title, style: Theme.of(sheetContext).textTheme.headlineSmall),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: SingleChildScrollView(
                // Clear of the home indicator or gesture bar; the keyboard, when
                // open, already lifts the sheet above it.
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  0,
                  AppSpacing.screenMargin,
                  AppSpacing.screenMargin +
                      (MediaQuery.viewInsetsOf(sheetContext).bottom > 0
                          ? 0
                          : MediaQuery.paddingOf(sheetContext).bottom),
                ),
                child: builder(sheetContext),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
