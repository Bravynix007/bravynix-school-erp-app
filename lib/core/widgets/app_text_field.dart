import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A label above the field, an optional red star, then the field. The theme
/// supplies the fill, corners and focus ring. `mono` sets IDs and codes in
/// tabular figures.
class AppTextField extends StatelessWidget {
  const new({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.required = false,
    this.mono = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;

  /// Shown under the field in red, with an icon, and replaces the helper.
  final String? error;
  final bool required;
  final bool mono;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = mono ? theme.textTheme.bodyMedium?.merge(AppTextStyles.code) : theme.textTheme.bodyMedium;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, required: required),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          label: label,
          isRequired: required,
          child: TextField(
            controller: controller,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            inputFormatters: inputFormatters,
            autofillHints: autofillHints,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            onTap: onTap,
            style: style,
            decoration: fieldDecoration(
              hint: hint,
              helper: helper,
              error: error,
              prefixIcon: prefixIcon,
              suffix: suffix,
            ),
          ),
        ),
      ],
    );
  }
}

/// The text above a field. The label and its star are hidden from screen
/// readers: the field speaks its own label and a "required" state (spoken in
/// the phone's language by the platform), so nothing is said twice.
class FieldLabel extends StatelessWidget {
  const new({required this.label, this.required = false, super.key});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.ink);
    return ExcludeSemantics(
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: style?.copyWith(color: AppColors.error),
              ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// The decoration every AppTextField-family control shares.
InputDecoration fieldDecoration({
  String? hint,
  String? helper,
  String? error,
  IconData? prefixIcon,
  Widget? suffix,
}) {
  return InputDecoration(
    hintText: hint,
    helperText: helper,
    helperMaxLines: 3,
    errorText: error,
    errorMaxLines: 3,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
    suffixIcon: suffix,
  );
}
