import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// A single-choice dropdown that looks like [AppTextField]. Controlled: the
/// caller holds the value.
class AppDropdownField<T> extends StatelessWidget {
  const new({
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint,
    this.helper,
    this.error,
    this.required = false,
    super.key,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? helper;
  final String? error;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, required: required),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          label: required ? '$label, required' : label,
          child: InputDecorator(
            isEmpty: value == null,
            decoration: fieldDecoration(helper: helper, error: error),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                hint: hint == null ? null : Text(hint!),
                borderRadius: BorderRadius.circular(AppRadius.field),
                style: Theme.of(context).textTheme.bodyMedium,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
