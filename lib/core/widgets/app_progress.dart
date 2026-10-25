import 'package:bravynix_school_erp/core/a11y/reduce_motion.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// How far along something is, as a bar: fee collected, syllabus covered. The
/// fill is the accent on a sunken track. Screen readers say [semanticLabel]
/// ("Fee collected") and then the percentage, so the figure is never carried by
/// the fill alone; put the amounts in the label if they matter ("Fee collected,
/// 50,000 of 80,000 rupees"). The fill moves to a new value over 200 ms unless
/// Reduce Motion is on.
class AppProgressBar extends StatelessWidget {
  const new({required this.value, required this.semanticLabel, this.color, this.height = 8, super.key})
    : assert(value >= 0 && value <= 1, 'value is a fraction from 0 to 1');

  /// 0 to 1.
  final double value;
  final String semanticLabel;

  /// The fill; the accent by default. A status colour for a fee that is overdue,
  /// but the status must also be in words, in the label or beside the bar
  /// (WCAG 1.4.1).
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.primary;
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      role: SemanticsRole.progressBar,
      label: semanticLabel,
      value: '${_percent(value)}%',
      minValue: '0',
      maxValue: '100',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: height,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: value),
              duration: duration,
              builder: (context, shown, _) => Stack(
                children: [
                  const Positioned.fill(child: ColoredBox(color: AppColors.sunken)),
                  FractionallySizedBox(
                    widthFactor: shown,
                    alignment: AlignmentDirectional.centerStart,
                    child: ColoredBox(
                      color: fill,
                      child: SizedBox(height: height),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same as a ring, for a headline figure: attendance 94%. The centre holds
/// any widget, usually the figure. The ring grows with the text size, as far as
/// the width allows, so the figure inside keeps its room; if it still does not
/// fit it is drawn smaller rather than cut.
class AppProgressRing extends StatelessWidget {
  const new({
    required this.value,
    required this.semanticLabel,
    this.center,
    this.color,
    this.size = 72,
    this.strokeWidth = 8,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction from 0 to 1');

  final double value;
  final String semanticLabel;
  final Widget? center;
  final Color? color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? Theme.of(context).colorScheme.primary;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final wanted = size * (scale < 1 ? 1.0 : scale);
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      role: SemanticsRole.progressBar,
      label: semanticLabel,
      value: '${_percent(value)}%',
      minValue: '0',
      maxValue: '100',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final edge = wanted > constraints.maxWidth ? constraints.maxWidth : wanted;
            return SizedBox.square(
              dimension: edge,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: value),
                    duration: duration,
                    builder: (context, shown, _) => SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: shown,
                        strokeWidth: strokeWidth,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.sunken,
                        color: fill,
                      ),
                    ),
                  ),
                  if (center != null)
                    Padding(
                      padding: EdgeInsets.all(strokeWidth + AppSpacing.xxs),
                      child: Center(
                        child: FittedBox(fit: BoxFit.scaleDown, child: center),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Whole percent for a screen reader. Never says 100% until it is complete, nor
/// 0% once there is some progress ("Fee collected 100%" while money is due would
/// be wrong).
int _percent(double value) {
  if (value >= 1) return 100;
  if (value <= 0) return 0;
  return (value * 100).round().clamp(1, 99);
}
