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

  final String countryCode;
  final String number;

  /// `+91 9876543210`.
  String get display => '+$countryCode $number';

  Map<String, String> toJson() => {'countryCode': countryCode, 'number': number};

  @override
  List<Object?> get props => [countryCode, number];
}
