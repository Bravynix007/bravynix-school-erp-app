import 'package:equatable/equatable.dart';

/// One person who holds Admin access to an Institution (INS-08): the staff member and the name they go by.
class InstitutionAdmin extends Equatable {
  const new({required this.institutionId, required this.staffMemberId, required this.displayName});

  final String institutionId;
  final String staffMemberId;
  final String displayName;

  @override
  List<Object?> get props => [institutionId, staffMemberId, displayName];
}
