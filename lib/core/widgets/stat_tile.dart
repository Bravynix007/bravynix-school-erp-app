import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// A KPI tile: a label, one big figure and an optional note under it
/// ("+3 this week"). Figures are tabular, so a column of tiles lines up, and a
/// figure never wraps (₹1,24,500 split over two lines can be misread); put
/// tiles side by side in a [StatTileRow], which stacks them when they do not
/// fit.
class StatTile extends StatelessWidget {
  const new({required this.label, required this.value, this.note, this.icon, this.onTap, super.key});

  final String label;
  final String value;
  final String? note;
  final IconData? icon;
  final VoidCallback? onTap;

  static const _figures = [FontFeature.tabularFigures()];

  /// The width this tile needs so that no figure or word is broken.
  double minWidth(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final valueWidth = measureText(context, value, text.headlineMedium?.copyWith(fontFeatures: _figures));
    final labelWidth = longestWordWidth(context, label, text.bodySmall) + (icon == null ? 0 : 18 + AppSpacing.xs);
    final noteWidth = note == null ? 0.0 : longestWordWidth(context, note!, text.bodySmall);
    final widest = [valueWidth, labelWidth, noteWidth].reduce((a, b) => a > b ? a : b);
    // Card padding on both sides and its 1 px border.
    return widest + AppSpacing.md * 2 + 2;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: scheme.onPrimaryContainer),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(child: Text(label, style: text.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: text.headlineMedium?.copyWith(fontFeatures: _figures),
            ),
          ),
          if (note != null) Text(note!, style: text.bodySmall?.copyWith(color: AppColors.inkTertiary)),
        ],
      ),
    );
  }
}

/// Stat tiles side by side while each has room for its figure and words, one
/// under another when it does not (large text, a narrow phone).
class StatTileRow extends StatelessWidget {
  const new({required this.tiles, super.key});

  final List<StatTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.sm;
        final cell = (constraints.maxWidth - gap * (tiles.length - 1)) / tiles.length;
        final fits = tiles.every((tile) => tile.minWidth(context) <= cell);
        if (fits) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tile in tiles) ...[
                if (tile != tiles.first) const SizedBox(width: gap),
                Expanded(child: tile),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final tile in tiles) ...[
              if (tile != tiles.first) const SizedBox(height: gap),
              SizedBox(width: double.infinity, child: tile),
            ],
          ],
        );
      },
    );
  }
}
