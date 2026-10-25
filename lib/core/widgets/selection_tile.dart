import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/ring_ink_well.dart';
import 'package:bravynix_school_erp/core/widgets/text_measure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// The row behind [AppCheckboxTile] and [AppRadioTile] (use those): a mark, a title and an
/// optional note. The whole row is the target, 56 px tall at least, and it
/// grows when the text wraps at large sizes.
class SelectionTile extends StatelessWidget {
  const new({
    required this.title,
    required this.checked,
    required this.radio,
    required this.onTap,
    super.key,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool checked;

  /// A round mark that excludes its siblings, instead of a square one.
  final bool radio;
  final VoidCallback? onTap;

  /// At the end of the row. It is part of the row's one control, so it must be
  /// plain (a count, an icon, a tag), never a button of its own.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final enabled = onTap != null;
    final IconData mark;
    if (radio) {
      mark = checked ? Icons.radio_button_checked : Icons.radio_button_unchecked;
    } else {
      mark = checked ? Icons.check_box : Icons.check_box_outline_blank;
    }
    // The empty mark is the control's boundary, so it is the field outline colour (3:1, WCAG 1.4.11).
    final markColour = !enabled
        ? AppColors.disabled
        : checked
        ? theme.colorScheme.primary
        : AppColors.fieldBorder;
    final titleStyle = text.bodyLarge?.copyWith(color: enabled ? AppColors.ink : AppColors.disabled);
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        inMutuallyExclusiveGroup: radio,
        enabled: enabled,
        child: RingInkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.listTile),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  ExcludeSemantics(child: Icon(mark, size: 24, color: markColour)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    // A word wider than the line is shrunk to fit it rather than broken in half.
                    child: LayoutBuilder(
                      builder: (context, constraints) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: titleStyle,
                            textScaler: fitWordScaler(context, title, titleStyle, constraints.maxWidth),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: text.bodySmall,
                              textScaler: fitWordScaler(context, subtitle!, text.bodySmall, constraints.maxWidth),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A checkbox row: "I have read the instructions", one of several choices.
/// `onChanged: null` disables it.
class AppCheckboxTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// At the end of the row. It is part of the row's one control, so it must be
  /// plain (a count, an icon, a tag), never a button of its own.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SelectionTile(
    title: title,
    subtitle: subtitle,
    checked: value,
    radio: false,
    trailing: trailing,
    onTap: onChanged == null ? null : () => onChanged!(!value),
  );
}

/// One option of a group where exactly one can be chosen. Put several in an
/// [AppRadioGroup], or in your own column with the same `groupValue`.
class AppRadioTile<T> extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;

  /// At the end of the row. It is part of the row's one control, so it must be
  /// plain (a count, an icon, a tag), never a button of its own.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SelectionTile(
    title: title,
    subtitle: subtitle,
    checked: value == groupValue,
    radio: true,
    trailing: trailing,
    onTap: onChanged == null ? null : () => onChanged!(value),
  );
}

/// A column of [AppRadioTile]s for `options`, with the group named for screen
/// readers ("Fee frequency").
class AppRadioGroup<T> extends StatelessWidget {
  const new({
    required this.label,
    required this.options,
    required this.titleOf,
    required this.value,
    required this.onChanged,
    this.subtitleOf,
    super.key,
  });

  /// Spoken as the name of the group.
  final String label;
  final List<T> options;
  final String Function(T option) titleOf;
  final String? Function(T option)? subtitleOf;
  final T? value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.radioGroup,
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in options)
            AppRadioTile<T>(
              title: titleOf(option),
              subtitle: subtitleOf?.call(option),
              value: option,
              groupValue: value,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}
