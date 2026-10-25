import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// One filter of an [AppFilterBar]: a name ("Class"), and what is chosen
/// ("7-B"), or `null` when it is not applied. Tapping it opens the caller's
/// picker (a bottom sheet of options).
class AppFilter {
  const new({required this.label, required this.onTap, this.value});

  final String label;
  final String? value;
  final VoidCallback onTap;
}

/// The filters above a list, as pills that wrap onto more lines (never a
/// sideways scroll that hides some of them), and a "Clear" button once any is
/// applied. An applied pill shows its value, a tick and the accent wash; the
/// words, not the colour alone, say which are on.
///
/// The Clear button removes itself once it has worked, so focus moves to the
/// first pill, not to nowhere (WCAG 2.4.3).
class AppFilterBar extends StatefulWidget {
  const new({required this.filters, required this.clearLabel, this.onClear, this.pillHint, super.key});

  final List<AppFilter> filters;

  /// "Clear filters".
  final String clearLabel;

  /// Called by the Clear button; the button shows only when some filter has a value.
  final VoidCallback? onClear;

  /// Said after each pill's name by a screen reader, so that it is clear a
  /// picker opens: "Opens choices".
  final String? pillHint;

  @override
  State<AppFilterBar> createState() => _AppFilterBarState();
}

class _AppFilterBarState extends State<AppFilterBar> {
  final _firstPill = FocusNode(debugLabel: 'First filter');

  @override
  void dispose() {
    _firstPill.dispose();
    super.dispose();
  }

  void _clear() {
    widget.onClear!();
    // The button is gone after this frame; put focus where the person can go on.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _firstPill.context != null) _firstPill.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final anyApplied = widget.filters.any((f) => f.value != null);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (index, filter) in widget.filters.indexed)
          _FilterPill(filter: filter, hint: widget.pillHint, focusNode: index == 0 ? _firstPill : null),
        if (anyApplied && widget.onClear != null) TextButton(onPressed: _clear, child: Text(widget.clearLabel)),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const new({required this.filter, this.hint, this.focusNode});

  final AppFilter filter;
  final String? hint;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final applied = filter.value != null;
    final shape = BorderRadius.circular(AppRadius.chip);
    final foreground = applied ? scheme.onSecondaryContainer : scheme.onSurface;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: applied,
        hint: hint,
        child: Material(
          borderOnForeground: false,
          color: applied ? scheme.secondaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: shape,
            side: applied ? BorderSide.none : const BorderSide(color: AppColors.border),
          ),
          child: RingInkWell(
            onTap: filter.onTap,
            focusNode: focusNode,
            borderRadius: shape,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: AppSpacing.minTouchTarget,
                minHeight: AppSpacing.minTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.xs,
                  top: AppSpacing.xs,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (applied) ...[
                      Icon(Icons.check, size: 18, color: foreground),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final text = applied ? '${filter.label}: ${filter.value}' : filter.label;
                          final style = theme.textTheme.labelLarge?.copyWith(color: foreground);
                          return Text(
                            text,
                            style: style,
                            textScaler: fitWordScaler(context, text, style, constraints.maxWidth),
                          );
                        },
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: foreground),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
