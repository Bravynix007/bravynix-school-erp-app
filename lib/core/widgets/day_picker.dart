import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/widgets/app_date_field.dart';
import 'package:flutter/material.dart';

/// Opens the calendar between [firstDay] and [lastDay], on [day] (`YYYY-MM-DD`) or, with none, on [initialDay] or
/// today, kept inside the range. Answers the day chosen as `YYYY-MM-DD`, or null when the calendar is closed without a
/// choice.
Future<String?> pickSchoolDay(
  BuildContext context, {
  required DateTime firstDay,
  required DateTime lastDay,
  String? day,
  DateTime? initialDay,
}) async {
  final start = (day == null ? null : Formatters.parseDay(day)) ?? initialDay ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: start.isBefore(firstDay) ? firstDay : (start.isAfter(lastDay) ? lastDay : start),
    firstDate: firstDay,
    lastDate: lastDay,
  );
  return picked == null ? null : Formatters.isoDay(picked);
}

/// A day that is always set: a date field that opens the calendar. [day] and [onChanged] carry `YYYY-MM-DD`; with no
/// [onChanged] the field is off.
class DayField extends StatelessWidget {
  const new({
    required this.label,
    required this.day,
    required this.onChanged,
    required this.firstDay,
    required this.lastDay,
    this.error,
    super.key,
  });

  final String label;
  final String day;
  final ValueChanged<String>? onChanged;
  final DateTime firstDay;
  final DateTime lastDay;
  final String? error;

  @override
  Widget build(BuildContext context) => AppDateField(
    label: label,
    valueText: Formatters.schoolDate(day),
    error: error,
    onTap: onChanged == null
        ? null
        : () async {
            final picked = await pickSchoolDay(context, day: day, firstDay: firstDay, lastDay: lastDay);
            if (picked != null) onChanged!(picked);
          },
  );
}
