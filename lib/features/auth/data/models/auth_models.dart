import 'package:bravynix_school_erp/core/storage/token_storage.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';

/// JSON → domain for the auth answers (API design 10.1, 10.2). Unknown fields
/// are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class AuthModels {
  static Map<String, dynamic> _map(Object? json) =>
      json is Map<String, dynamic> ? json : throw const FormatException('Expected a JSON object');

  static OtpRequested otpRequested(Object? json) {
    final map = _map(json);
    return OtpRequested(
      resendAfter: Duration(seconds: (map['resendAfterSeconds'] as num?)?.toInt() ?? 60),
      expiresIn: Duration(seconds: (map['expiresInSeconds'] as num?)?.toInt() ?? 600),
    );
  }

  static AuthTokens tokens(Object? json) {
    final map = _map(json);
    return AuthTokens(accessToken: map['accessToken'] as String, refreshToken: map['refreshToken'] as String);
  }

  static Person person(Object? json) {
    final map = _map(json);
    return Person(
      id: map['id'] as String,
      email: map['email'] as String,
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      preferredLanguage: map['preferredLanguage'] as String? ?? 'en',
    );
  }

  static AuthContext? context(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final role = RoleCode.fromCode((json['roleCode'] as num?)?.toInt());
    if (role == null) return null;
    return AuthContext(
      role: role,
      societyId: json['societyId'] as String?,
      societyName: json['societyName'] as String?,
      staffMemberId: json['staffMemberId'] as String?,
      homeInstitutionId: json['homeInstitutionId'] as String?,
      isBlocked: json['isBlocked'] as bool? ?? false,
      children: [
        for (final child in (json['children'] as List<dynamic>? ?? const []))
          if (child is Map<String, dynamic>)
            LinkedChild(
              studentId: child['studentId'] as String,
              firstName: child['firstName'] as String,
              institutionName: child['institutionName'] as String? ?? '',
              classSection: child['classSection'] as String? ?? '',
              isBlocked: child['isBlocked'] as bool? ?? false,
            ),
      ],
    );
  }

  /// The verify answer and `GET /v1/me` share person and contexts.
  static AuthSession session(Object? json) {
    final map = _map(json);
    final contexts = [
      for (final item in (map['contexts'] as List<dynamic>? ?? const [])) ?context(item),
    ];
    final session = map['session'];
    final active = session is Map<String, dynamic> ? context(session['activeContext']) : null;
    return AuthSession(
      person: person(map['person']),
      contexts: contexts,
      activeContext: active ?? (contexts.length == 1 ? contexts.single : null),
    );
  }
}
