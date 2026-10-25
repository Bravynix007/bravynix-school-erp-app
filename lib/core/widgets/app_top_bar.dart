import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// The white bar at the top of the home screen and plain screens: an optional
/// logo (or any leading widget), a small label over the title, and actions
/// such as the bell and the avatar. With `onBack` it becomes the back-arrow
/// variant. It is 64 px at the default text size and grows with larger text
/// instead of cutting the title, so it is a normal widget (put it at the top
/// of a Column) and not a fixed-height `Scaffold.appBar`.
class AppTopBar extends StatelessWidget {
  const new({
    required this.title,
    this.overline,
    this.leading,
    this.onBack,
    this.backTooltip,
    this.actions = const [],
    super.key,
  }) : assert(onBack == null || backTooltip != null, 'The back button needs a tooltip: it is its spoken name');

  final String title;

  /// A small line above the title ("Good afternoon").
  final String? overline;

  /// A logo tile or similar, shown when there is no back button.
  final Widget? leading;
  final VoidCallback? onBack;
  final String? backTooltip;
  final List<Widget> actions;

  /// The least height of the bar, below the status bar.
  static const height = 64.0;

  /// The width assumed for [leading] (a 40 px logo tile and its gap).
  static const _leadingWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = onBack != null
        ? IconButton(
            onPressed: onBack,
            tooltip: backTooltip,
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(minimumSize: const Size.square(AppSpacing.minTouchTarget)),
          )
        : leading;
    final start = onBack != null ? AppSpacing.xxs : AppSpacing.screenMargin;
    const end = AppSpacing.xxs;
    final leadWidth = onBack != null
        ? AppSpacing.minTouchTarget + AppSpacing.xxs
        : (leading == null ? 0.0 : _leadingWidth);

    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: height),
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: start, end: end, top: AppSpacing.xs, bottom: AppSpacing.xs),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final overlineStyle = theme.textTheme.labelMedium?.copyWith(color: AppColors.inkSecondary);
                final titleStyle = theme.textTheme.titleLarge;
                // Beside the logo and actions only if the longest word fits there; else on a line of its own.
                final beside = constraints.maxWidth - leadWidth - actions.length * AppSpacing.minTouchTarget;
                final need = [
                  longestWordWidth(context, title, titleStyle),
                  if (overline != null) longestWordWidth(context, overline!, overlineStyle),
                ].reduce((a, b) => a > b ? a : b);
                final stacked = need > beside;
                final room = stacked ? constraints.maxWidth : beside;
                final text = Semantics(
                  header: true,
                  container: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (overline != null)
                        Text(
                          overline!,
                          style: overlineStyle,
                          textScaler: fitWordScaler(context, overline!, overlineStyle, room),
                        ),
                      Text(title, style: titleStyle, textScaler: fitWordScaler(context, title, titleStyle, room)),
                    ],
                  ),
                );
                if (stacked) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [?lead, const Spacer(), ...actions]),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                        child: text,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    if (lead != null) ...[lead, SizedBox(width: onBack != null ? AppSpacing.xxs : AppSpacing.sm)],
                    Expanded(child: text),
                    ...actions,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
