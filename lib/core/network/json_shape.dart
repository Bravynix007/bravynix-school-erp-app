/// The two shapes every answer is read from. A body that is not the shape the contract promises is a
/// [FormatException], which the repository turns into a failure instead of showing a wrong screen.
Map<String, dynamic> jsonObject(Object? json) =>
    json is Map<String, dynamic> ? json : throw const FormatException('Expected a JSON object');

List<dynamic> jsonList(Object? json) =>
    json is List<dynamic> ? json : throw const FormatException('Expected a JSON array');
