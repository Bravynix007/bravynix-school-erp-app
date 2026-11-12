import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:equatable/equatable.dart';

/// Where a person lives. The place is given by master IDs, which the screen turns into names.
class Address extends Equatable {
  const new({this.line1, this.line2, this.countryId, this.stateId, this.cityId, this.pincode});

  /// `{ line1, line2, countryId, stateId, cityId, pincode }`, each possibly null.
  factory fromJson(Object? raw) {
    final json = jsonObject(raw);
    return Address(
      line1: json['line1'] as String?,
      line2: json['line2'] as String?,
      countryId: json['countryId'] as String?,
      stateId: json['stateId'] as String?,
      cityId: json['cityId'] as String?,
      pincode: json['pincode'] as String?,
    );
  }

  final String? line1;
  final String? line2;
  final String? countryId;
  final String? stateId;
  final String? cityId;
  final String? pincode;

  bool get isEmpty =>
      line1 == null && line2 == null && countryId == null && stateId == null && cityId == null && pincode == null;

  /// What is set is sent; with [clearing] what is empty is sent as `null` too, so a change clears the field.
  Map<String, Object?> toJson({required bool clearing}) => {
    for (final entry in {
      'line1': line1,
      'line2': line2,
      'countryId': countryId,
      'stateId': stateId,
      'cityId': cityId,
      'pincode': pincode,
    }.entries)
      if (clearing || entry.value != null) entry.key: entry.value,
  };

  @override
  List<Object?> get props => [line1, line2, countryId, stateId, cityId, pincode];
}
