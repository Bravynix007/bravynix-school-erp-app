import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// A single-choice dropdown that looks and behaves like [AppTextField]: same
/// outline, accent focus border, disabled look and error line. Controlled:
/// the caller holds the value.
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
    this.requiredLabel,
    super.key,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;

  /// Null disables the field.
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? helper;
  final String? error;
  final bool required;

  /// The word "Required" in the app's language, spoken as a hint.
  final String? requiredLabel;

  @override
  Widget build(BuildContext context) {
    assert(!required || requiredLabel != null, 'A required field needs requiredLabel (the spoken word "Required")');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, required: required),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          label: label,
          isRequired: required,
          hint: required ? requiredLabel : null,
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            // Not dense, and no fixed item height: a dense button is one line tall, so a chosen value that wraps at a
            // large text size would be cut off. The field takes the height of its tallest entry and the menu rows
            // their own.
            isDense: false,
            hint: hint == null ? null : Text(hint!),
            borderRadius: BorderRadius.circular(AppRadius.field),
            style: Theme.of(context).textTheme.bodyMedium,
            // Each entry is at least 48 px tall, as tall as a text field's text and padding, so the field has no
            // padding above or below to stay level with a text field.
            decoration: fieldDecoration(helper: helper, error: error).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }
}
