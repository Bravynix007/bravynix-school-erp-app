import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// A shortcut on the home screen: an icon in an accent wash with a short name
/// under it ("Attendance", "Fees"). The whole tile is one button.
class QuickAccessTile extends StatelessWidget {
  const new({required this.icon, required this.label, required this.onTap, this.labelRoom, super.key});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// The width the label has. [QuickAccessGrid] sets it, so that a word wider
  /// than the tile (one column, largest text) is drawn smaller, not broken.
  final double? labelRoom;

  /// The width this tile needs so that its longest word is not broken.
  double minWidth(BuildContext context) =>
      longestWordWidth(context, label, Theme.of(context).textTheme.labelMedium) + 2 * AppSpacing.sm + 2;

  QuickAccessTile withLabelRoom(double room) =>
      QuickAccessTile(icon: icon, label: label, onTap: onTap, labelRoom: room);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, size: 24, color: scheme.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium,
            textScaler: labelRoom == null
                ? null
                : fitWordScaler(context, label, theme.textTheme.labelMedium, labelRoom!),
          ),
        ],
      ),
    );
  }
}

/// Quick-access tiles in rows of equal width: as many per row as fit (four at
/// most), fewer at large text, down to one. Tiles in a row share the height
/// of the tallest.
class QuickAccessGrid extends StatelessWidget {
  const new({required this.tiles, super.key});

  final List<QuickAccessTile> tiles;

  static const double _gap = AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widest = tiles.map((t) => t.minWidth(context)).fold<double>(96, (a, b) => a > b ? a : b);
        var columns = ((constraints.maxWidth + _gap) / (widest + _gap)).floor().clamp(1, 4);
        columns = columns > tiles.length ? tiles.length : columns;
        final room = (constraints.maxWidth - _gap * (columns - 1)) / columns - 2 * AppSpacing.sm - 2;
        final rows = <Widget>[];
        for (var start = 0; start < tiles.length; start += columns) {
          final end = start + columns > tiles.length ? tiles.length : start + columns;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + columns; i++) ...[
                    if (i > start) const SizedBox(width: _gap),
                    Expanded(child: i < end ? tiles[i].withLabelRoom(room) : const SizedBox.shrink()),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[if (i > 0) const SizedBox(height: _gap), rows[i]],
          ],
        );
      },
    );
  }
}
