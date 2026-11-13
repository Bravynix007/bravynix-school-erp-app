import 'package:flutter/services.dart';

/// What an Aadhaar field takes: twelve digits, which people type with spaces or hyphens between the groups.
List<TextInputFormatter> aadhaarInputFormatters() => [
  FilteringTextInputFormatter.allow(RegExp('[0-9 -]')),
  LengthLimitingTextInputFormatter(14),
];
