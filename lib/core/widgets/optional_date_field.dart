import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/theme/app_spacing.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:bravynix_school_erp/core/widgets/app_icon_button.dart';
import 'package:flutter/material.dart';

/// A day that may be left empty: a date field that opens the calendar, with a button that clears it. [day] and
/// [onChanged] carry `YYYY-MM-DD`, or null for no day. The calendar opens on [day] or, with none, on [initialDay].
class OptionalDateField extends StatelessWidget {
  const new({
    required this.label,
    required this.day,
    required this.onChanged,
    required this.hint,
    required this.clearLabel,
    required this.firstDay,
    required this.lastDay,
    this.initialDay,
    this.error,
    super.key,
  });

  final String label;
  final String? day;
  final ValueChanged<String?> onChanged;

  /// On the empty field: "Choose a date".
  final String hint;

  /// What the clear button says to a screen reader: "Clear Date of birth".
  final String clearLabel;
  final DateTime firstDay;
  final DateTime lastDay;

  /// Where the calendar opens when no day is set; today by default.
  final DateTime? initialDay;
  final String? error;

  Future<void> _pick(BuildContext context) async {
    final start = (day == null ? null : DateTime.tryParse(day!)) ?? initialDay ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(firstDay) ? firstDay : (start.isAfter(lastDay) ? lastDay : start),
      firstDate: firstDay,
      lastDate: lastDay,
    );
    if (picked != null) onChanged(Formatters.isoDay(picked));
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: AppDateField(
          label: label,
          valueText: day == null ? '' : Formatters.schoolDate(day!),
          hint: hint,
          error: error,
          onTap: () => _pick(context),
        ),
      ),
      if (day != null) ...[
        const SizedBox(width: AppSpacing.xs),
        AppIconButton(icon: Icons.close, tooltip: clearLabel, onPressed: () => onChanged(null)),
      ],
    ],
  );
}
