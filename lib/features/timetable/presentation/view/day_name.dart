import 'package:intl/intl.dart';

/// The name of a school [day], 1 (Monday) to 6 (Saturday), in [locale].
String dayName(String locale, int day) =>
    // 1 January 2024 was a Monday, so the day number is the date.
    DateFormat.EEEE(locale).format(DateTime(2024, 1, day));
