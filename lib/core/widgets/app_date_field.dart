import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// A field that opens a date picker when tapped. The screen shows the picker
/// and passes the formatted date back as `valueText`, so the widget has no
/// date logic of its own.
class AppDateField extends StatelessWidget {
  const new({
    required this.label,
    required this.valueText,
    required this.onTap,
    this.hint,
    this.helper,
    this.error,
    this.required = false,
    super.key,
  });

  final String label;
  final String valueText;
  final VoidCallback? onTap;
  final String? hint;
  final String? helper;
  final String? error;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, required: required),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          button: true,
          enabled: onTap != null,
          focusable: onTap != null,
          label: required ? '$label, required' : label,
          value: valueText,
          onTap: onTap,
          child: ExcludeSemantics(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.field),
              child: InputDecorator(
                isEmpty: valueText.isEmpty,
                decoration: fieldDecoration(
                  hint: hint,
                  helper: helper,
                  error: error,
                  prefixIcon: Icons.calendar_today_outlined,
                ).copyWith(enabled: onTap != null),
                child: Text(valueText, style: style),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
