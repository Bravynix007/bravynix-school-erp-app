import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six visual slots backed by one editable field for paste, selection,
/// screen readers and one-time-code autofill.
class CodeEntry extends StatefulWidget {
  const new({
    required this.controller,
    required this.label,
    required this.onChanged,
    required this.onSubmitted,
    required this.enabled,
    required this.invalid,
    super.key,
  });

  static const length = 6;

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final bool enabled;
  final bool invalid;

  @override
  State<CodeEntry> createState() => _CodeEntryState();
}

class _CodeEntryState extends State<CodeEntry> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _field({
    required TextStyle style,
    required InputDecoration decoration,
    bool showCursor = true,
    TextAlign textAlign = TextAlign.center,
  }) => TextField(
    key: const Key('login.code'),
    controller: widget.controller,
    focusNode: _focusNode,
    autofocus: true,
    enabled: widget.enabled,
    showCursor: showCursor,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    textDirection: TextDirection.ltr,
    textAlign: textAlign,
    autofillHints: const [AutofillHints.oneTimeCode],
    autocorrect: false,
    enableSuggestions: false,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(CodeEntry.length)],
    style: style,
    decoration: decoration,
    onChanged: widget.onChanged,
    onSubmitted: (_) => widget.onSubmitted(),
  );

  @override
  Widget build(BuildContext context) {
    final digitStyle = AppTextStyles.verificationDigit.copyWith(color: AppColors.ink);
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final digitSize = digitStyle.fontSize!;
    final digitScale = textScaler.scale(digitSize) / digitSize;
    const gap = AppSpacing.xs;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - gap * (CodeEntry.length - 1)) / CodeEntry.length;
        if (cellWidth < AppSpacing.xxl || digitScale >= 1.4) {
          return _field(
            style: digitStyle,
            decoration: InputDecoration(labelText: widget.label),
          );
        }
        final measure = TextPainter(
          text: TextSpan(text: '0', style: digitStyle),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        final slotSpacing = (cellWidth + gap - measure.width) / digitScale;
        measure.dispose();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Text(widget.label, style: theme.textTheme.labelLarge)),
            const SizedBox(height: AppSpacing.xs),
            Stack(
              children: [
                // The transparent field keeps its text spacing and selection
                // near the slots so the native paste and selection menu work.
                MergeSemantics(
                  child: Semantics(
                    label: widget.label,
                    child: _field(
                      style: digitStyle.copyWith(
                        color: Colors.transparent,
                        letterSpacing: slotSpacing, // token-ok: follows the slot widths.
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                        constraints: BoxConstraints(minHeight: AppSizes.buttonLarge),
                        contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      showCursor: false,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([widget.controller, _focusNode]),
                        builder: (context, child) {
                          final value = widget.controller.value;
                          final caret = value.selection.isValid ? value.selection.extentOffset : value.text.length;
                          return Row(
                            textDirection: TextDirection.ltr,
                            spacing: gap,
                            children: [
                              for (var i = 0; i < CodeEntry.length; i++)
                                Expanded(
                                  child: _DigitSlot(
                                    digit: i < value.text.length ? value.text[i] : null,
                                    style: digitStyle,
                                    focused: _focusNode.hasFocus && i == caret.clamp(0, CodeEntry.length - 1),
                                    selected:
                                        value.selection.isValid &&
                                        i >= value.selection.start &&
                                        i < value.selection.end,
                                    invalid: widget.invalid,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DigitSlot extends StatelessWidget {
  const new({
    required this.digit,
    required this.style,
    required this.focused,
    required this.selected,
    required this.invalid,
  });

  final String? digit;
  final TextStyle style;
  final bool focused;
  final bool selected;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = invalid
        ? AppColors.errorBg
        : selected
        ? scheme.primary
        : focused || digit != null
        ? scheme.primaryContainer
        : AppColors.canvas;
    final border = invalid ? AppColors.error : (focused ? scheme.primary : AppColors.fieldBorder);

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: focused ? 2 : 1),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: digit == null
          ? const SizedBox(
              width: AppSpacing.xs,
              child: Divider(color: AppColors.fieldBorder),
            )
          : Text(
              digit!,
              style: selected && !invalid ? style.copyWith(color: scheme.onPrimary) : style,
              textDirection: TextDirection.ltr,
            ),
    );
  }
}
