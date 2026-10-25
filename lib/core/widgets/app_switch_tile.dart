import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';

/// A settings row with an on/off switch that takes effect at once ("Notify
/// parents of absence"). The whole row toggles, not only the switch, and the
/// switch is drawn for show: the row is the one control that is focused and
/// announced. `onChanged: null` disables it.
///
/// When a word of the text would not fit beside the switch (large text), the
/// switch moves under the text, at the end of its own line.
class AppSwitchTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _switchWidth = 52.0;
  static const double _iconWidth = 24.0 + AppSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final enabled = onChanged != null;
    final titleStyle = text.bodyLarge?.copyWith(color: enabled ? AppColors.ink : AppColors.disabled);
    final subtitleStyle = text.bodySmall;
    final leading = icon == null ? 0.0 : _iconWidth;

    final control = ExcludeFocus(
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: Switch(value: value, onChanged: enabled ? (_) {} : null),
        ),
      ),
    );

    return MergeSemantics(
      child: Semantics(
        toggled: value,
        enabled: enabled,
        child: RingInkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.listTile),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final inlineRoom = constraints.maxWidth - leading - _switchWidth - AppSpacing.sm;
                  final stackedRoom = constraints.maxWidth - leading;
                  bool fits(double room) =>
                      longestWordWidth(context, title, titleStyle) <= room &&
                      (subtitle == null || longestWordWidth(context, subtitle!, subtitleStyle) <= room);
                  final inline = fits(inlineRoom);
                  final room = inline ? inlineRoom : stackedRoom;
                  final words = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle, textScaler: fitWordScaler(context, title, titleStyle, room)),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: subtitleStyle,
                          textScaler: fitWordScaler(context, subtitle!, subtitleStyle, room),
                        ),
                    ],
                  );
                  final iconWidget = icon == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ExcludeSemantics(child: Icon(icon, color: AppColors.inkSecondary)),
                        );
                  if (inline) {
                    return Row(
                      children: [
                        ?iconWidget,
                        Expanded(child: words),
                        const SizedBox(width: AppSpacing.sm),
                        control,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ?iconWidget,
                          Expanded(child: words),
                        ],
                      ),
                      Align(alignment: AlignmentDirectional.centerEnd, child: control),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
