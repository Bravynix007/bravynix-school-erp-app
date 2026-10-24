import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// An [InkWell] that also draws the 2 px keyboard focus ring (3:1 or better
/// on every surface). The ring shows only while the person is using a
/// keyboard or switch, not after a tap.
class RingInkWell extends StatefulWidget {
  const new({required this.child, this.onTap, this.borderRadius = BorderRadius.zero, super.key});

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  @override
  State<RingInkWell> createState() => _RingInkWellState();
}

class _RingInkWellState extends State<RingInkWell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final showRing = _focused && FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: showRing ? Border.all(color: AppColors.focusRing, width: 2) : null,
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        onFocusChange: (value) => setState(() => _focused = value),
        child: widget.child,
      ),
    );
  }
}
