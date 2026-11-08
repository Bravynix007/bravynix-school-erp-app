import 'package:equatable/equatable.dart';

/// A predefined class or a class category as the class shows it (API design 10.4j).
class NamedRef extends Equatable {
  const new({required this.id, required this.code, required this.name});

  final String id;
  final String code;
  final String name;

  @override
  List<Object?> get props => [id, code, name];
}

/// The class category that has streams, and only it (decision 7).
const preUniversityCategoryCode = 'PRE_UNIVERSITY';

/// One class of an Institution: a predefined class, with a stream for Pre-University, under a name the school gives it.
class SchoolClass extends Equatable {
  const new({
    required this.id,
    required this.institutionId,
    required this.predefinedClass,
    required this.category,
    required this.displayName,
    required this.sectionCount,
    required this.version,
    this.streamName,
    this.code,
  });

  final String id;
  final String institutionId;
  final NamedRef predefinedClass;
  final NamedRef category;
  final String? streamName;
  final String displayName;

  /// The short code the school uses, when it has one.
  final String? code;

  /// The active sections of the class.
  final int sectionCount;

  /// What a change must send back, so one made meanwhile is told apart (409 VERSION_CONFLICT).
  final int version;

  @override
  List<Object?> get props => [
    id,
    institutionId,
    predefinedClass,
    category,
    streamName,
    displayName,
    code,
    sectionCount,
    version,
  ];
}

/// A predefined class an Institution may add, because it offers the class's category.
class ClassChoice extends Equatable {
  const new({required this.predefinedClass, required this.category});

  final NamedRef predefinedClass;
  final NamedRef category;

  /// A stream belongs only to Pre-University classes (decision 7); the API refuses it elsewhere.
  bool get allowsStream => category.code == preUniversityCategoryCode;

  @override
  List<Object?> get props => [predefinedClass, category];
}

/// The choices grouped by category, in the order the masters list them.
extension ClassChoices on List<ClassChoice> {
  /// The categories of the choices, each once.
  List<NamedRef> get categories => {for (final choice in this) choice.category}.toList();

  List<ClassChoice> inCategory(NamedRef category) => [
    for (final choice in this)
      if (choice.category == category) choice,
  ];
}

/// One class of a bulk add: a predefined class, with a stream where the class allows one.
class NewClass extends Equatable {
  const new({required this.predefinedClassId, this.streamName});

  final String predefinedClassId;
  final String? streamName;

  @override
  List<Object?> get props => [predefinedClassId, streamName];
}
