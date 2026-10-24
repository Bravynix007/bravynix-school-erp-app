import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';

/// A field that opens a date picker when tapped. The screen shows the picker
/// and passes the formatted date back as `valueText`, so the widget has no
/// date logic of its own. It takes keyboard focus (Enter or Space opens the
/// picker), shows the accent focus border, and dims while pressed. Screen
/// readers hear the label, the date, and the helper or error as the hint.
class AppDateField extends StatefulWidget {
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
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final spokenHint = [
      widget.error ?? widget.helper,
      if (widget.valueText.isEmpty) widget.hint,
    ].whereType<String>().join('. ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: widget.label, required: widget.required),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          button: true,
          enabled: enabled,
          focusable: enabled,
          focused: _focused,
          isRequired: widget.required,
          label: widget.label,
          value: widget.valueText,
          hint: spokenHint.isEmpty ? null : spokenHint,
          onTap: widget.onTap,
          child: ExcludeSemantics(
            child: FocusableActionDetector(
              enabled: enabled,
              mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())},
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                child: InputDecorator(
                  isEmpty: widget.valueText.isEmpty,
                  isFocused: _focused,
                  isHovering: _pressed,
                  decoration: fieldDecoration(
                    hint: widget.hint,
                    helper: widget.helper,
                    error: widget.error,
                    prefixIcon: Icons.calendar_today_outlined,
                  ).copyWith(enabled: enabled),
                  child: Text(widget.valueText, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
