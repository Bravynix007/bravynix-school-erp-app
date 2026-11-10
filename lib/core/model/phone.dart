import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:equatable/equatable.dart';

/// A phone number as the API carries it: the country code without the plus, and the digits.
class Phone extends Equatable {
  const new({required this.countryCode, required this.number});

  /// `{ countryCode, number }`.
  factory fromJson(Object? raw) {
    final json = jsonObject(raw);
    return Phone(countryCode: json['countryCode'] as String, number: json['number'] as String);
  }

  /// What a person typed: the dial code without a plus or spaces, the number without spaces (people type either way).
  /// Null when no number was typed. A number without its dial code is kept as it is, so the API names the field.
  static Phone? typed(String countryCode, String number) {
    final digits = number.replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return null;
    return Phone(countryCode: countryCode.replaceAll(RegExp(r'[\s+]'), ''), number: digits);
  }

  final String countryCode;
  final String number;

  /// `+91 9876543210`.
  String get display => '+$countryCode $number';

  Map<String, String> toJson() => {'countryCode': countryCode, 'number': number};

  @override
  List<Object?> get props => [countryCode, number];
}
