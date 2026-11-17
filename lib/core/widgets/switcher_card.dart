import 'package:bravynix_school_erp/core/widgets/app_bottom_sheet.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/selection_tile.dart';
import 'package:flutter/material.dart';

/// Names the one of several things a screen is about (an Institution, a child) and, with more than one, opens a sheet to
/// switch to another. A sheet rather than a dropdown, so a long name wraps at large text sizes instead of being cut.
/// With a single option the card only names it: there is nothing to switch to, so it is no button and has no hint.
class SwitcherCard<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.selected,
    required this.idOf,
    required this.titleOf,
    required this.hint,
    required this.sheetTitle,
    required this.optionKeyPrefix,
    required this.onSelected,
    this.subtitleOf,
    this.detail,
    super.key,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) idOf;
  final String Function(T option) titleOf;

  /// A second line for an option in the sheet (an Institution's code, a child's class).
  final String? Function(T option)? subtitleOf;

  /// Under the name on the card: what to know about the selected option at a glance.
  final String? detail;

  /// Says the card can be tapped ("Change Institution").
  final String hint;
  final String sheetTitle;

  /// Each option in the sheet is keyed `$optionKeyPrefix.<id>`.
  final String optionKeyPrefix;

  /// Called with the option the person picked; not called when the sheet is closed or the current one is picked.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSwitch = options.length > 1;
    return AppCard(
      onTap: canSwitch ? () => _choose(context) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titleOf(selected), style: theme.textTheme.titleMedium),
          if (detail != null && detail!.isNotEmpty) Text(detail!, style: theme.textTheme.bodySmall),
          if (canSwitch) Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }

  Future<void> _choose(BuildContext context) async {
    final id = await showAppBottomSheet<String>(
      context: context,
      title: sheetTitle,
      builder: (sheet) => Column(
        children: [
          for (final option in options)
            AppRadioTile<String>(
              key: ValueKey('$optionKeyPrefix.${idOf(option)}'),
              title: titleOf(option),
              subtitle: subtitleOf?.call(option),
              value: idOf(option),
              groupValue: idOf(selected),
              onChanged: (id) => Navigator.of(sheet).pop(id),
            ),
        ],
      ),
    );
    if (id == null) return;
    final chosen = options.where((option) => idOf(option) == id).firstOrNull;
    if (chosen != null && idOf(chosen) != idOf(selected)) onSelected(chosen);
  }
}
