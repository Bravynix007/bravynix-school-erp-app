import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_card.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// One day of a school week as a card that opens and closes: the day's name over a short summary ("3 periods"), and
/// under them, once open, the [child] (the periods of that day). The header is one button that says whether the day is
/// open, so a screen reader hears "Monday, 3 periods, expanded" and the periods only when they are shown.
class TimetableDayCard extends StatefulWidget {
  const new({required this.title, required this.summary, required this.child, this.initiallyOpen = false, super.key});

  final String title;
  final String summary;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<TimetableDayCard> createState() => _TimetableDayCardState();
}

class _TimetableDayCardState extends State<TimetableDayCard> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            button: true,
            expanded: _open,
            label: '${widget.title}, ${widget.summary}',
            excludeSemantics: true,
            onTap: () => setState(() => _open = !_open),
            child: RingInkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: text.titleMedium,
                              textScaler: fitWordScaler(context, widget.title, text.titleMedium, constraints.maxWidth),
                            ),
                            Text(widget.summary, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(_open ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
