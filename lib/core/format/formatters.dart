/// Display formats from PRD 11.2 and DESIGN.md 6: dates DD-MM-YYYY, times
/// 24 h in India Standard Time, money in Indian grouping (₹1,24,500.00).
abstract final class Formatters {
  /// Every Institution runs on IST, which has no daylight saving (DDD principle 10).
  static const _ist = Duration(hours: 5, minutes: 30);

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// A school day `2026-10-23` → `23-10-2026`, with no time zone shift.
  static String schoolDate(String day) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(day);
    return match == null ? day : '${match[3]}-${match[2]}-${match[1]}';
  }

  /// An instant → `23-10-2026 10:15` in IST.
  static String instant(DateTime value) {
    final ist = value.toUtc().add(_ist);
    return '${_two(ist.day)}-${_two(ist.month)}-${ist.year} ${_two(ist.hour)}:${_two(ist.minute)}';
  }

  /// Money arrives as an exact decimal string ("124500.00", API design 7.3)
  /// and is formatted without passing through a double.
  static String money(String amount) {
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(amount.trim());
    if (match == null) return amount;
    final sign = match[1]!;
    final integer = match[2]!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final fraction = (match[3] ?? '').padRight(2, '0');
    return '$sign₹${_groupIndian(integer)}.$fraction';
  }

  /// 1,24,500: the last three digits, then pairs.
  static String _groupIndian(String digits) {
    if (digits.length <= 3) return digits;
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final pairs = <String>[];
    for (var end = head.length; end > 0; end -= 2) {
      pairs.insert(0, head.substring(end - 2 < 0 ? 0 : end - 2, end));
    }
    return '${pairs.join(',')},$tail';
  }
}
