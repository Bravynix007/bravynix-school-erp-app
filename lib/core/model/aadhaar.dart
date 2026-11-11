/// An Aadhaar number as a person types it and as it is shown.
abstract final class Aadhaar {
  /// What a person typed: spaces and hyphens may separate the digits. The twelve digits, or null when it is not twelve
  /// digits with a first digit of 2 to 9. The check digit is left to the server (422 `INVALID_AADHAAR`).
  static String? typed(String input) {
    final digits = input.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^[2-9]\d{11}$').hasMatch(digits) ? digits : null;
  }

  /// Twelve digits in groups of four, as printed on the card: `2345 6789 0123`.
  static String grouped(String digits) => [
    for (var start = 0; start < digits.length; start += 4)
      digits.substring(start, start + 4 > digits.length ? digits.length : start + 4),
  ].join(' ');
}
