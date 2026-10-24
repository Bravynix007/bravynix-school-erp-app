import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// A grey placeholder block that pulses while data loads. With the phone's
/// "remove animations" setting on it stays still.
class SkeletonBox extends StatefulWidget {
  const new({this.width, this.height = 16, this.radius = AppRadius.sm, super.key});

  final double? width;
  final double height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.sunken, AppColors.border, _controller.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
        child: SizedBox(width: widget.width, height: widget.height),
      ),
    );
  }
}

/// Placeholder rows shaped like a list of people: avatar, two lines.
class SkeletonList extends StatelessWidget {
  const new({required this.semanticLabel, this.rows = 5, super.key});

  /// Spoken once for the whole list, e.g. "Loading".
  final String semanticLabel;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i += 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: AppRadius.full),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 160),
                          SizedBox(height: AppSpacing.xs),
                          SkeletonBox(width: 100, height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
