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

  @override
  List<Object?> get props => [member, designationName, categoryName, countryName, stateName, cityName];
}
