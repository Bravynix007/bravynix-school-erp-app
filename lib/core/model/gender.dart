/// The blood groups a record can hold (DDD 9.5).
const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

/// PRD 11.2: 1 Male, 2 Female, 3 Other.
enum Gender {
  male(1),
  female(2),
  other(3);

  new(this.code);

  final int code;

  static Gender? fromCode(Object? code) {
    for (final gender in values) {
      if (gender.code == code) return gender;
    }
    return null;
  }
}
