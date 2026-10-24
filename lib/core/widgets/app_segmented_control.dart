import 'package:flutter/material.dart';

/// Two to four exclusive options side by side (Day / Week / Month).
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
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}
