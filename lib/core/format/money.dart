/// Money as the API sends it: a decimal string with at most two decimals
/// ("1250.00"), never a floating-point number (SDD, Money). It is formatted
/// with Indian digit grouping, `₹1,24,500.00`, by working on the digits, so no
/// rounding or binary fraction can change a paisa.
final RegExp _decimal = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$');

/// Formats [decimal] ("124500", "124500.5", "-250.00") as `₹1,24,500.00`.
/// A negative amount is `-₹250.00`. Throws [FormatException] for anything that
/// is not a plain decimal with up to two decimals, rather than showing a wrong
/// amount.
String formatRupees(String decimal, {bool withSymbol = true}) {
  final match = _decimal.firstMatch(decimal.trim());
  if (match == null) throw FormatException('Not a money amount with up to two decimals', decimal);
  final negative = match.group(1) == '-';
  final whole = match.group(2)!.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final paise = (match.group(3) ?? '').padRight(2, '0');
  final isZero = RegExp(r'^0+$').hasMatch(whole) && paise == '00';
  final sign = negative && !isZero ? '-' : '';
  return '$sign${withSymbol ? '₹' : ''}${_groupIndian(whole)}.$paise';
}

/// 1234567 -> 12,34,567: the last three digits, then pairs.
String _groupIndian(String digits) {
  if (digits.length <= 3) return digits;
  final head = digits.substring(0, digits.length - 3);
  final tail = digits.substring(digits.length - 3);
  final pairs = <String>[];
  for (var end = head.length; end > 0; end -= 2) {
    pairs.insert(0, head.substring(end - 2 < 0 ? 0 : end - 2, end));
  }
  return '${pairs.join(',')},$tail';
}
