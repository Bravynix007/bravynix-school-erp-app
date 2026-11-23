import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// "November 2026" between two arrows that step a month back and forward. [month] is the first day of the month. The
/// arrows are 48 px targets with spoken names, and the label is a header for a screen reader.
class MonthStepper extends StatelessWidget {
  const new({
    required this.month,
    required this.onChanged,
    required this.previousTooltip,
    required this.nextTooltip,
    super.key,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final String previousTooltip;
  final String nextTooltip;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return Row(
      children: [
        IconButton(
          key: const Key('monthStepper.previous'),
          tooltip: previousTooltip,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        Expanded(
          child: Semantics(
            header: true,
            liveRegion: true,
            // A month and a year: on a narrow phone at a large text size it shrinks to fit rather than breaking a word.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                DateFormat.yMMMM(locale).format(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
        ),
        IconButton(
          key: const Key('monthStepper.next'),
          tooltip: nextTooltip,
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}
