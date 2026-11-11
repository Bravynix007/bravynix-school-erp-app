import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:equatable/equatable.dart';

/// A staff member with the names of the master entries their IDs stand for, as the profile shows them.
class StaffProfile extends Equatable {
  const new(
    this.member, {
    this.categoryName,
    this.designationName,
    this.countryName,
    this.stateName,
    this.cityName,
  });

  final StaffMember member;
  final String? designationName;
  final String? categoryName;
  final String? countryName;
  final String? stateName;
  final String? cityName;

  /// The same profile with [member] replaced: the names stand for fields the access actions do not change.
  StaffProfile withMember(StaffMember member) => StaffProfile(
    member,
    categoryName: categoryName,
    designationName: designationName,
    countryName: countryName,
    stateName: stateName,
    cityName: cityName,
  );

  @override
  List<Object?> get props => [member, designationName, categoryName, countryName, stateName, cityName];
}
