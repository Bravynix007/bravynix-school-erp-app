import 'package:bravynix_school_erp/features/auth/data/models/auth_models.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The AUTH-02 example from API design 10.2 (synthetic data).
  final verify = <String, dynamic>{
    'accessToken': 'access',
    'accessTokenExpiresAt': '2026-10-23T04:25:00.000Z',
    'refreshToken': 'refresh',
    'session': {'id': '0192f6b0-11aa-7c3d-9e10-5a6b7c8d9e0f', 'activeContext': null},
    'person': {
      'id': '0192f3a1-0b2c-7d3e-8f40-1a2b3c4d5e6f',
      'email': 'asha.rao@example.com',
      'firstName': 'Asha',
      'lastName': 'Rao',
      'preferredLanguage': 'kn',
      'accountStatus': 1,
    },
    'contexts': [
      {
        'roleCode': 4,
        'societyId': '0192f3b0-2c3d-7e4f-9a50-2b3c4d5e6f70',
        'societyName': 'Sunrise Education Trust',
        'staffMemberId': '0192f3c4-3d4e-7f50-8b61-3c4d5e6f7081',
        'homeInstitutionId': '0192f3b7-4e5f-7061-9c72-4d5e6f708192',
        'isBlocked': false,
      },
      {
        'roleCode': 5,
        'children': [
          {
            'studentId': '0192f4c2-5f60-7172-8d83-5e6f708192a3',
            'firstName': 'Diya',
            'institutionName': 'Green Valley School',
            'classSection': '7th - A',
            'isBlocked': false,
          },
        ],
      },
      // A role this app version does not know is skipped, not a crash (API design 5.2).
      {'roleCode': 9},
    ],
    'requiredNotices': [
      {'noticeType': 1, 'noticeVersion': '2026-10'},
    ],
  };

  test('parses tokens', () {
    final tokens = AuthModels.tokens(verify);
    expect(tokens.accessToken, 'access');
    expect(tokens.refreshToken, 'refresh');
  });

  test('parses person and contexts; two contexts need the role chooser', () {
    final session = AuthModels.session(verify);
    expect(session.person.displayName, 'Asha Rao');
    expect(session.person.preferredLanguage, 'kn');
    expect(session.contexts.map((c) => c.role), [RoleCode.teacherStaff, RoleCode.studentParent]);
    expect(session.contexts.first.societyName, 'Sunrise Education Trust');
    expect(session.contexts.last.children.single.classSection, '7th - A');
    expect(session.activeContext, isNull);
    expect(session.needsRoleChoice, isTrue);
  });

  test('one context becomes the active one', () {
    final single = {
      ...verify,
      'contexts': [(verify['contexts'] as List<Object?>).first],
    };
    final session = AuthModels.session(single);
    expect(session.activeContext?.role, RoleCode.teacherStaff);
    expect(session.needsRoleChoice, isFalse);
  });

  test('the OTP answer gives the resend gap', () {
    final sent = AuthModels.otpRequested({'resendAfterSeconds': 60, 'expiresInSeconds': 600});
    expect(sent.resendAfter, const Duration(minutes: 1));
    expect(sent.expiresIn, const Duration(minutes: 10));
  });
}
