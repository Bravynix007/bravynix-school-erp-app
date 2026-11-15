import 'package:bravynix_school_erp/core/network/api_failure.dart';

/// What a form finds wrong before it sends anything, as the API would name it, so each shows under its own field. The
/// server stays the judge of everything else.
class FieldProblems {
  final _errors = <FieldError>[];

  /// [field] is wrong for a reason the form knows, such as an Aadhaar number that is not twelve digits.
  void add(String field, String code) => _errors.add(FieldError(field: field, code: code, message: ''));

  /// A field the form marks as required: [value] is something other than spaces.
  void requireText(String field, String value) {
    if (value.trim().isEmpty) _errors.add(FieldError.required(field));
  }

  /// A choice the form marks as required.
  void requireChoice(String field, Object? choice) {
    if (choice == null) _errors.add(FieldError.required(field));
  }

  /// The refusal to show, or null when nothing is wrong.
  ApiFailure? get failure => _errors.isEmpty ? null : ApiFailure.invalid(_errors);
}
