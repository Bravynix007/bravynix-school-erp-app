import 'package:bravynix_school_erp/features/academic_years/domain/academic_years_repository.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_repository.dart';
import 'package:bravynix_school_erp/features/blocks/domain/blocks_repository.dart';
import 'package:bravynix_school_erp/features/classes/domain/class_catalogue.dart';
import 'package:bravynix_school_erp/features/classes/domain/classes_repository.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:bravynix_school_erp/features/platform_dues/domain/platform_dues_repository.dart';
import 'package:bravynix_school_erp/features/subjects/domain/subjects_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAcademicYearsRepository extends Mock implements AcademicYearsRepository;

class MockClassCatalogue extends Mock implements ClassCatalogue;

class MockClassesRepository extends Mock implements ClassesRepository;

class MockAuthRepository extends Mock implements AuthRepository;

class MockBlocksRepository extends Mock implements BlocksRepository;

class MockInstitutionsRepository extends Mock implements InstitutionsRepository;

class MockMastersRepository extends Mock implements MastersRepository;

class MockPlatformDuesRepository extends Mock implements PlatformDuesRepository;

class MockSubjectsRepository extends Mock implements SubjectsRepository;

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

const ownerNorth = AuthContext(role: RoleCode.societyOwner, societyId: 's1', societyName: 'North Trust');
const ownerSouth = AuthContext(role: RoleCode.societyOwner, societyId: 's2', societyName: 'South Trust');

/// Two roles and no active one: the role chooser shows.
const twoRoleSession = AuthSession(person: testPerson, contexts: [ownerNorth, ownerSouth]);
