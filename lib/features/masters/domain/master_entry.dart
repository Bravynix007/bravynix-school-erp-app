import 'package:equatable/equatable.dart';

/// The shared lists every Institution picks from (API design 10.4g).
enum MasterType {
  countries('countries'),
  states('states'),
  cities('cities'),
  classCategories('class-categories'),
  predefinedClasses('predefined-classes'),
  predefinedSections('predefined-sections'),
  designations('designations');

  new(this.path);

  /// The name in `/v1/masters/{path}`.
  final String path;

  /// The query parameter that narrows this master to one parent, or null when it has none.
  String? get parentParameter => switch (this) {
    MasterType.states => 'countryId',
    MasterType.cities => 'stateId',
    MasterType.predefinedClasses => 'classCategoryId',
    _ => null,
  };
}

/// One shown entry of a master. [parentId] is the country of a state, the state of a city or the class category
/// of a predefined class; [numericValue] is a predefined class's number.
class MasterEntry extends Equatable {
  const new({required this.id, required this.name, this.code, this.parentId, this.numericValue});

  final String id;
  final String name;
  final String? code;
  final String? parentId;
  final int? numericValue;

  @override
  List<Object?> get props => [id, name, code, parentId, numericValue];
}
