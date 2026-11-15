import 'package:bravynix_school_erp/features/people/domain/place_names.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:equatable/equatable.dart';

/// A staff member with the names of the master entries their IDs stand for, as the profile shows them.
class StaffProfile extends Equatable {
  const new(
    this.member, {
    this.categoryName,
    this.designationName,
    this.places = const PlaceNames(),
  });

  final StaffMember member;
  final String? designationName;
  final String? categoryName;
  final PlaceNames places;

  /// The same profile with [member] replaced: the names stand for fields the access actions do not change.
  StaffProfile withMember(StaffMember member) => StaffProfile(
    member,
    categoryName: categoryName,
    designationName: designationName,
    places: places,
  );

  @override
  List<Object?> get props => [member, designationName, categoryName, places];
}
