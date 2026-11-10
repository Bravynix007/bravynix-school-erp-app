import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_profile.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_error_text.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_profile_page.dart';
import 'package:bravynix_school_erp/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

class _MockProfileBloc extends MockBloc<StaffProfileEvent, StaffProfileState> implements StaffProfileBloc;

void main() {
  late _MockProfileBloc bloc;
  setUpAll(() => registerFallbackValue(const StaffProfileRequested()));
  setUp(() => bloc = _MockProfileBloc());

  Future<void> pump(
    WidgetTester tester,
    StaffProfileState state, {
    double textScale = 1,
    Size size = const Size(400, 1600),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<StaffProfileBloc>.value(value: bloc, child: const StaffProfileView()),
      textScale: textScale,
      size: size,
    );
  }

  testWidgets('shows everything a full profile has', (tester) async {
    await pump(tester, const StaffProfileLoaded(kavyaProfile));
    for (final text in [
      'Kavya Nair',
      'T-014',
      'Mathematics Teacher',
      'Lower Primary',
      'Female',
      '17-04-1990',
      'O+',
      'Indian',
      'kavya.nair@example.com',
      '+91 9876543210',
      '9876500000',
      '12 Lake Road\nNear the park\nBengaluru, Karnataka, India\n560066',
      'Full time',
      '01-06-2020',
      '31-03-2026',
      'B.Ed',
      'Education · Mathematics · Mysore University · 2014',
      'Anil Nair (Father)',
      '+91 9876511111 · 9876522222',
      'Mini Nair',
      '+91 9876533333',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Blocked'), findsNothing);
  });

  testWidgets('shows only what a bare profile has, with the Blocked badge', (tester) async {
    await pump(tester, const StaffProfileLoaded(raviProfile));
    expect(find.text('Ravi'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
    expect(find.text('Employee ID'), findsNothing);
    expect(find.text('Gender'), findsNothing);
    expect(find.text('Address'), findsNothing);
    expect(find.text('Employment'), findsNothing);
    expect(find.text('Education'), findsNothing);
    expect(find.text('Emergency contacts'), findsNothing);
  });

  for (final (type, gender, label) in [
    (EmploymentType.partTime, Gender.male, 'Part time'),
    (EmploymentType.visiting, Gender.other, 'Visiting'),
    (EmploymentType.contract, Gender.female, 'Contract'),
  ]) {
    testWidgets('names the $label employment type and the ${gender.name} gender', (tester) async {
      await pump(
        tester,
        StaffProfileLoaded(
          StaffProfile(
            StaffMember(
              id: 'f1',
              homeInstitutionId: 'i1',
              email: 'a@example.com',
              firstName: 'A',
              classCategoryId: 'c1',
              mobile: mobile,
              address: const StaffAddress(),
              educations: const [],
              emergencyContacts: const [],
              isBlocked: false,
              version: 1,
              employmentType: type,
              gender: gender,
            ),
            categoryName: 'Lower Primary',
          ),
        ),
      );
      expect(find.text(label), findsOneWidget);
      expect(find.text({Gender.male: 'Male', Gender.female: 'Female', Gender.other: 'Other'}[gender]!), findsOneWidget);
    });
  }

  testWidgets('shows a placeholder while it loads', (tester) async {
    await pump(tester, const StaffProfileLoading());
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('says why it failed, and loads again on Try again', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure.network()));
    expect(find.byKey(const Key('staffProfile.failed')), findsOneWidget);
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const StaffProfileRequested())).called(1);
  });

  testWidgets('says a staff member who is gone is not found, with nothing to retry', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')));
    expect(find.byKey(const Key('staffProfile.notFound')), findsOneWidget);
    expect(find.text('This staff member could not be found. They may have been deactivated.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('says a role that may not see staff has no access', (tester) async {
    await pump(tester, const StaffProfileFailed(ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')));
    expect(find.byKey(const Key('staffProfile.forbidden')), findsOneWidget);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, const StaffProfileLoaded(kavyaProfile), textScale: 2, size: const Size(320, 4000));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });

  testWidgets('staffErrorText says the caller own record is off limits and a missing one is gone', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          l10n = AppLocalizations.of(context);
          return const SizedBox();
        },
      ),
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x')),
      "You can't do this to your own record.",
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 404, code: 'NOT_FOUND', message: 'x')),
      'This staff member could not be found. They may have been deactivated.',
    );
    expect(
      staffErrorText(l10n, const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'x')),
      l10n.errorForbidden,
    );
  });
}
