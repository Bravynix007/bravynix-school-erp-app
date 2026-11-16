import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/people/presentation/bloc/access_block_bloc.dart';
import 'package:bravynix_school_erp/features/students/domain/student_profile.dart';
import 'package:bravynix_school_erp/features/students/presentation/bloc/student_profile_bloc.dart';
import 'package:bravynix_school_erp/features/students/presentation/view/student_access_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/students.dart';

class _MockProfileBloc extends MockBloc<StudentProfileEvent, StudentProfileState> implements StudentProfileBloc;

const _already = ApiFailure(statusCode: 409, code: 'INVALID_STATE', message: 'server words');

void main() {
  late MockStudentsRepository students;
  late _MockProfileBloc profile;

  setUpAll(() => registerFallbackValue(const StudentProfileRequested()));
  setUp(() {
    students = MockStudentsRepository();
    profile = _MockProfileBloc();
    when(() => students.block('p3')).thenAnswer((_) async => chitraBlockedRecord);
    when(() => students.unblock('p3')).thenAnswer((_) async => chitraRecord);
  });

  Future<void> pump(WidgetTester tester, {bool blocked = false, double textScale = 1}) => tester.pumpAppScaled(
    Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<StudentProfileBloc>.value(value: profile),
          BlocProvider(
            create: (_) => AccessBlockBloc<StudentRecord>(
              blocked ? chitraBlockedRecord : chitraRecord,
              isBlocked: (record) => record.isBlocked,
              block: (record) => students.block(record.id),
              unblock: (record) => students.unblock(record.id),
              read: (record) => students.student(record.id),
            ),
          ),
        ],
        child: const SingleChildScrollView(child: StudentAccessSection()),
      ),
    ),
    textScale: textScale,
    size: const Size(400, 900),
  );

  testWidgets('says parents can see the child, and offers to block', (tester) async {
    await pump(tester);
    expect(find.text('Parents and guardians can see this child.'), findsOneWidget);
    expect(find.text('Block parent access'), findsOneWidget);
    expect(find.text('Restore parent access'), findsNothing);
  });

  testWidgets('says parents cannot see the child, and offers to restore', (tester) async {
    await pump(tester, blocked: true);
    expect(find.textContaining('Parent access is blocked.'), findsOneWidget);
    expect(find.text('Restore parent access'), findsOneWidget);
  });

  testWidgets('asks first, blocks on confirmation, tells the profile and says it was done', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Block parent access to Chitra?'), findsOneWidget);
    verifyNever(() => students.block(any()));
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block parent access')));
    await tester.pumpAndSettle();
    verify(() => students.block('p3')).called(1);
    verify(() => profile.add(const StudentProfileRecordChanged(chitraBlockedRecord))).called(1);
    expect(find.text('Parent access to Chitra blocked'), findsOneWidget);
    expect(find.text('Restore parent access'), findsOneWidget);
  });

  testWidgets('lifts a block on confirmation and says it was done', (tester) async {
    await pump(tester, blocked: true);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Restore parent access to Chitra?'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Restore parent access')));
    await tester.pumpAndSettle();
    verify(() => students.unblock('p3')).called(1);
    verify(() => profile.add(const StudentProfileRecordChanged(chitraRecord))).called(1);
    expect(find.text('Parent access to Chitra restored'), findsOneWidget);
  });

  testWidgets('does nothing when the question is cancelled', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => students.block(any()));
    verifyNever(() => profile.add(any()));
  });

  testWidgets('says someone else got there first, and shows how the child is now', (tester) async {
    when(() => students.block('p3')).thenThrow(_already);
    when(() => students.student('p3')).thenAnswer((_) async => chitraBlockedRecord);
    await pump(tester);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block parent access')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('studentAccess.error')), findsOneWidget);
    expect(find.textContaining('already changed'), findsOneWidget);
    expect(find.text('Restore parent access'), findsOneWidget);
    verify(() => profile.add(const StudentProfileRecordChanged(chitraBlockedRecord))).called(1);
  });

  testWidgets('reads the profile again when the student was deactivated meanwhile', (tester) async {
    when(() => students.block('p3')).thenThrow(const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x'));
    await pump(tester);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block parent access')));
    await tester.pumpAndSettle();
    verify(() => profile.add(const StudentProfileRequested())).called(1);
    verifyNever(() => profile.add(any(that: isA<StudentProfileRecordChanged>())));
  });

  testWidgets('cannot be pressed again while it works, so a second question does not open', (tester) async {
    final held = Completer<StudentRecord>();
    when(() => students.block('p3')).thenAnswer((_) => held.future);
    await pump(tester);
    await tester.tap(find.byKey(const Key('studentAccess.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block parent access')));
    await tester.pump();
    expect(tester.widget<AppButton>(find.byKey(const Key('studentAccess.toggle'))).onPressed, isNull);
    held.complete(chitraBlockedRecord);
    await tester.pumpAndSettle();
  });

  testWidgets('reads whole at a large text scale', (tester) async {
    await pump(tester, blocked: true, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 184), isEmpty);
  });
}
