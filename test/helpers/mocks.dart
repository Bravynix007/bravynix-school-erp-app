import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository;

const testPerson = Person(
  id: 'p1',
  email: 'asha.rao@example.com',
  firstName: 'Asha',
  lastName: 'Rao',
  preferredLanguage: 'en',
);

const testSession = AuthSession(
  person: testPerson,
  contexts: [AuthContext(role: RoleCode.teacherStaff, societyId: 's1', societyName: 'Sunrise Education Trust')],
  activeContext: AuthContext(role: RoleCode.teacherStaff, societyId: 's1', societyName: 'Sunrise Education Trust'),
);
