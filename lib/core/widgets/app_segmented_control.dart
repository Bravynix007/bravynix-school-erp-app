import 'package:flutter/material.dart';

/// Two to four exclusive options side by side (Day / Week / Month). At large
/// text the tick on the chosen segment is dropped, so words are not broken to
/// make room for it; the chosen segment is still filled.
class AppSegmentedControl<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<T> options;
  final String Function(T option) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [
        for (final option in options) ButtonSegment<T>(value: option, label: Text(labelOf(option))),
      ],
      selected: {selected},
      showSelectedIcon: MediaQuery.textScalerOf(context).scale(14) / 14 <= 1.3,
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}
