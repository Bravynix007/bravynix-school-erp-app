import 'package:equatable/equatable.dart';

/// The boards an Institution can follow (PRD 11.4): 1 CBSE, 2 ICSE, 3 State Board, 4 IB, 5 IGCSE, 6 Other.
enum Board {
  cbse(1),
  icse(2),
  stateBoard(3),
  ib(4),
  igcse(5),
  other(6);

  new(this.code);

  final int code;

  static Board? fromCode(Object? code) {
    for (final board in values) {
      if (board.code == code) return board;
    }
    return null;
  }
}

/// One row of the Institutions list (INS-01).
class InstitutionSummary extends Equatable {
  const new({required this.id, required this.code, required this.name, this.place, this.board});

  final String id;
  final String code;
  final String name;

  /// The area or locality, such as "Whitefield".
  final String? place;
  final Board? board;

  @override
  List<Object?> get props => [id, code, name, place, board];
}

/// A class category an Institution offers (INS-03): it decides which classes the Institution can create.
class OfferedCategory extends Equatable {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// An Institution as INS-03 describes it, with what the detail screen shows.
class Institution extends Equatable {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.addressLine1,
    this.place,
    this.board,
    this.affiliationNumber,
    this.gstin,
    this.email,
    this.phone,
    this.telephone,
    this.addressLine2,
    this.pincode,
    this.classesOffered = const [],
  });

  final String id;
  final String code;
  final String name;
  final String? place;
  final Board? board;
  final String? affiliationNumber;
  final String? gstin;
  final String? email;

  /// Country code and number, as one string: `+91 9876543210`.
  final String? phone;
  final String? telephone;
  final String addressLine1;
  final String? addressLine2;
  final String? pincode;
  final List<OfferedCategory> classesOffered;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    place,
    board,
    affiliationNumber,
    gstin,
    email,
    phone,
    telephone,
    addressLine1,
    addressLine2,
    pincode,
    classesOffered,
  ];
}
