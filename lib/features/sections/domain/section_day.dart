import 'package:equatable/equatable.dart';

/// A section on a day: what a screen that reads or writes by section is pointed at, and what it was last pointed at.
class SectionDay extends Equatable {
  const new({required this.sectionId, required this.day});

  final String sectionId;

  /// `YYYY-MM-DD`.
  final String day;

  @override
  List<Object?> get props => [sectionId, day];
}
