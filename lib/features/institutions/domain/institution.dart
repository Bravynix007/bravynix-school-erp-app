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

/// A phone number as the API carries it: the country code without the plus, and the digits.
class Phone extends Equatable {
  const new({required this.countryCode, required this.number});

  final String countryCode;
  final String number;

  /// `+91 9876543210`.
  String get display => '+$countryCode $number';

  @override
  List<Object?> get props => [countryCode, number];
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

/// An Institution as INS-03 describes it.
class Institution extends Equatable {
  const new({
    required this.id,
    required this.code,
    required this.name,
    required this.addressLine1,
    this.version = 1,
    this.place,
    this.board,
    this.affiliationNumber,
    this.gstin,
    this.email,
    this.phone,
    this.telephone,
    this.addressLine2,
    this.pincode,
    this.countryId,
    this.stateId,
    this.cityId,
    this.classesOffered = const [],
  });

  final String id;
  final String code;
  final String name;

  /// What an edit must send back, so a change made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;
  final String? place;
  final Board? board;
  final String? affiliationNumber;
  final String? gstin;
  final String? email;
  final Phone? phone;
  final String? telephone;
  final String addressLine1;
  final String? addressLine2;
  final String? pincode;

  /// The place, as ids of the masters: names come from the masters repository.
  final String? countryId;
  final String? stateId;
  final String? cityId;
  final List<OfferedCategory> classesOffered;

  @override
  List<Object?> get props => [
    id,
    code,
    name,
    version,
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
    countryId,
    stateId,
    cityId,
    classesOffered,
  ];
}

/// What the Institution form sends (INS-02, INS-04): every field the form holds. A field left empty is `null`, which
/// on an edit clears it. The code is set when the Institution is added and never changed.
class InstitutionDraft extends Equatable {
  const new({
    required this.name,
    required this.code,
    required this.addressLine1,
    required this.classesOffered,
    this.place,
    this.board,
    this.affiliationNumber,
    this.gstin,
    this.email,
    this.phone,
    this.telephone,
    this.addressLine2,
    this.pincode,
    this.countryId,
    this.stateId,
    this.cityId,
  });

  final String name;
  final String code;
  final String addressLine1;

  /// The ids of the class categories the Institution offers.
  final List<String> classesOffered;
  final String? place;
  final Board? board;
  final String? affiliationNumber;
  final String? gstin;
  final String? email;
  final Phone? phone;
  final String? telephone;
  final String? addressLine2;
  final String? pincode;
  final String? countryId;
  final String? stateId;
  final String? cityId;

  @override
  List<Object?> get props => [
    name,
    code,
    addressLine1,
    classesOffered,
    place,
    board,
    affiliationNumber,
    gstin,
    email,
    phone,
    telephone,
    addressLine2,
    pincode,
    countryId,
    stateId,
    cityId,
  ];
}
