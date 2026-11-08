import 'package:equatable/equatable.dart';

/// One subject of the Society, taught in any of its Institutions (API design 10.4i).
class Subject extends Equatable {
  const new({required this.id, required this.name, required this.version, this.code});

  final String id;
  final String name;

  /// The short code the school uses, such as MATH; unique among the Society's subjects when set.
  final String? code;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  @override
  List<Object?> get props => [id, name, code, version];
}
