/// What a person typed into a field, as the API wants it. An empty field is a field that is not set.
abstract final class TypedText {
  /// The text without the spaces around it; null when nothing is left.
  static String? text(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// A number typed with spaces or hyphens between its digits, as people write phone numbers; null when nothing is
  /// left.
  static String? digits(String value) => text(value.replaceAll(RegExp(r'[\s-]'), ''));
}
