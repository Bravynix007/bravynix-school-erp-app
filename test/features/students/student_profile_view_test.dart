import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/students.dart';

class _MockProfileBloc extends MockBloc<StudentProfileEvent, StudentProfileState> implements StudentProfileBloc;

const _ashaProfile = StudentProfile(
  ashaRecord,
  placeName: 'Class 1 · Section A',
  countryName: 'India',
  stateName: 'Karnataka',
  cityName: 'Bengaluru',
);

ApiFailure _failure(int status, String code) => ApiFailure(statusCode: status, code: code, message: 'server words');

void main() {
  late _MockProfileBloc bloc;
  setUpAll(() => registerFallbackValue(const StudentProfileRequested()));
  setUp(() => bloc = _MockProfileBloc());

  Future<void> pump(
    WidgetTester tester,
    StudentProfileState state, {
    double textScale = 1,
    Size size = const Size(400, 2400),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StudentProfileBloc>.value(value: bloc, child: const StudentProfileView()),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('shows everything a full profile has', (tester) async {
    await pump(tester, const StudentProfileLoaded(_ashaProfile));
    for (final text in [
      'Asha Rao',
      'A-2026-014',
      '01-06-2026',
      'Class 1 · Section A · Roll 14',
      'Female',
      '17-04-2018',
      'O+',
      'Indian',
      'asha.rao@example.com',
      '+91 9876543210',
      '9876500000',
      '12 Lake Road\nNear the park\nBengaluru, Karnataka, India\n560066',
      'Anil Rao',
      'Father',
      '+91 9876511111',
      '9876522222',
      'anil.rao@example.com',
      'Engineer',
      'Mini',
      '+91 9876533333',
      'XXXX XXXX 1234',
      'BC-2018-77',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Primary guardian'), findsOneWidget);
    expect(find.text('Emergency contact'), findsOneWidget);
    expect(find.text('Blocked'), findsNothing);
    expect(find.text('Deactivated'), findsNothing);
  });

  testWidgets('shows only what a minimal record has, says it is deactivated and blocked, and what is not set', (
    tester,
  ) async {
    await pump(tester, const StudentProfileLoaded(StudentProfile(balaRecord)));
    expect(find.text('Bala'), findsOneWidget);
    expect(find.text('Deactivated'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Devi'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(2));
    expect(find.textContaining('No contact details are recorded'), findsOneWidget);
    for (final label in ['Admission ID', 'Admission date', 'Class and section', 'Gender', 'Date of birth']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    // The guardian has no relation known, so no line for it.
    expect(find.text('Father'), findsNothing);
  });

  testWidgets('shows the roll number alone when the section and class are not named', (tester) async {
    await pump(tester, const StudentProfileLoaded(StudentProfile(ashaRecord)));
    expect(find.text('Roll 14'), findsOneWidget);
  });

  testWidgets('shows the contact of a student who has an email and no mobile', (tester) async {
    final record = StudentRecord(
      id: 'p3',
      institutionId: 'i1',
      firstName: 'Chitra',
      mobile: const Phone(countryCode: '91', number: '9000000000'),
      address: ashaRecord.address,
      guardians: ashaRecord.guardians,
      identity: const StudentIdentity(),
      isBlocked: false,
      isActive: true,
      version: 1,
    );
    await pump(tester, StudentProfileLoaded(StudentProfile(record)));
    expect(find.text('+91 9000000000'), findsOneWidget);
    expect(find.textContaining('No contact details are recorded'), findsNothing);
  });

  group('before the profile is ready', () {
    testWidgets('shows a placeholder while it loads', (tester) async {
      await pump(tester, const StudentProfileLoading());
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('says why it could not be read, and starts again on Try again', (tester) async {
      await pump(tester, const StudentProfileFailed(ApiFailure.network()));
      expect(find.byKey(const Key('studentProfile.failed')), findsOneWidget);
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => bloc.add(const StudentProfileRequested())).called(1);
    });

    testWidgets('says the student could not be found, with no retry', (tester) async {
      await pump(tester, StudentProfileFailed(_failure(404, 'NOT_FOUND')));
      expect(find.byKey(const Key('studentProfile.notFound')), findsOneWidget);
      expect(find.text('This student could not be found. They may have been deactivated.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('says there is no access, with no retry', (tester) async {
      await pump(tester, StudentProfileFailed(_failure(403, 'FORBIDDEN')));
      expect(find.byKey(const Key('studentProfile.forbidden')), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const StudentProfileLoaded(_ashaProfile), textScale: 2, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester), isEmpty);
  });
}
