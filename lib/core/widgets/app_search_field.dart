import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';

/// A search box with a clear button that appears once something is typed.
class AppSearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.hint,
    required this.clearTooltip,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final String clearTooltip;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          hintMaxLines: 3,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: value.text.isEmpty
              ? null
              : AppIconButton(
                  icon: Icons.close,
                  tooltip: clearTooltip,
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
        ),
      ),
    );
  }
}
