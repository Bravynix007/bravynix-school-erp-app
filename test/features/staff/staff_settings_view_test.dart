import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/widgets/app_button.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_block_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/bloc/staff_profile_bloc.dart';
import 'package:bravynix_school_erp/features/staff/presentation/view/staff_settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/staff.dart';

class _MockBlockBloc extends MockBloc<StaffBlockEvent, StaffBlockState> implements StaffBlockBloc;

class _MockProfileBloc extends MockBloc<StaffProfileEvent, StaffProfileState> implements StaffProfileBloc;

void main() {
  late _MockBlockBloc bloc;
  late _MockProfileBloc profile;

  setUpAll(() {
    registerFallbackValue(const StaffBlockToggled());
    registerFallbackValue(const StaffProfileRequested());
    registerFallbackValue(StaffProfileMemberChanged(kavyaWith()));
  });

  setUp(() {
    bloc = _MockBlockBloc();
    profile = _MockProfileBloc();
  });

  final active = kavyaWith();
  final blocked = kavyaWith(isBlocked: true, version: 5);

  Future<void> pump(
    WidgetTester tester,
    StaffBlockState state, {
    double textScale = 1,
    Size size = const Size(400, 1000),
  }) {
    when(() => bloc.state).thenReturn(state);
    return tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<StaffBlockBloc>.value(value: bloc),
          BlocProvider<StaffProfileBloc>.value(value: profile),
        ],
        child: const Scaffold(body: StaffSettingsView()),
      ),
      textScale: textScale,
      size: size,
    );
  }

  AppButton toggle(WidgetTester tester) => tester.widget<AppButton>(find.byKey(const Key('staffSettings.toggle')));

  group('a staff member who can sign in', () {
    testWidgets('is told so, with Block access offered', (tester) async {
      await pump(tester, StaffBlockIdle(active));
      expect(find.text('They can use the app as staff.'), findsOneWidget);
      expect(find.text('Blocked'), findsNothing);
      expect(find.text('Block access'), findsOneWidget);
    });

    testWidgets('is blocked only once the person confirms', (tester) async {
      await pump(tester, StaffBlockIdle(active));
      await tester.tap(find.byKey(const Key('staffSettings.toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Block Kavya Nair?'), findsOneWidget);
      expect(find.textContaining('signed out at once'), findsOneWidget);
      verifyNever(() => bloc.add(any()));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block access')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffBlockToggled())).called(1);
    });

    testWidgets('is asked in red, as it is hard to undo at once', (tester) async {
      await pump(tester, StaffBlockIdle(active));
      await tester.tap(find.byKey(const Key('staffSettings.toggle')));
      await tester.pumpAndSettle();
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.danger);
    });

    testWidgets('is left as they are when the dialog is dismissed', (tester) async {
      await pump(tester, StaffBlockIdle(active));
      await tester.tap(find.byKey(const Key('staffSettings.toggle')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('is left as they are when the person cancels', (tester) async {
      await pump(tester, StaffBlockIdle(active));
      await tester.tap(find.byKey(const Key('staffSettings.toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      verifyNever(() => bloc.add(any()));
    });
  });

  group('a blocked staff member', () {
    testWidgets('is told so, with Unblock access offered', (tester) async {
      await pump(tester, StaffBlockIdle(blocked));
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.textContaining('They are blocked.'), findsOneWidget);
      expect(find.text('Unblock access'), findsOneWidget);
      expect(find.text('Block access'), findsNothing);
    });

    testWidgets('is unblocked only once the person confirms', (tester) async {
      await pump(tester, StaffBlockIdle(blocked));
      await tester.tap(find.byKey(const Key('staffSettings.toggle')));
      await tester.pumpAndSettle();
      expect(find.text('Unblock Kavya Nair?'), findsOneWidget);
      final confirm = find.descendant(of: find.byType(Dialog), matching: find.byType(AppButton)).last;
      expect(tester.widget<AppButton>(confirm).variant, AppButtonVariant.primary);
      verifyNever(() => bloc.add(any()));
      await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Unblock access')));
      await tester.pumpAndSettle();
      verify(() => bloc.add(const StaffBlockToggled())).called(1);
    });
  });

  testWidgets('shows progress on the button while it works', (tester) async {
    await pump(tester, StaffBlockWorking(active));
    expect(toggle(tester).loading, isTrue);
  });

  group('a refused block', () {
    testWidgets('says why, in words beside the button', (tester) async {
      await pump(
        tester,
        StaffBlockRefused(active, const ApiFailure(statusCode: 409, code: 'CANNOT_ACT_ON_SELF', message: 'x')),
      );
      expect(find.byKey(const Key('staffSettings.error')), findsOneWidget);
      expect(find.text("You can't do this to your own record."), findsOneWidget);
      expect(toggle(tester).loading, isFalse);
      expect(toggle(tester).onPressed, isNotNull);
    });

    testWidgets('names the Society Owner when an Institution Admin may not block an Admin', (tester) async {
      await pump(
        tester,
        StaffBlockRefused(active, const ApiFailure(statusCode: 403, code: 'FORBIDDEN', message: 'server words')),
      );
      expect(find.text('Only the Society Owner can change the access of an Institution Admin.'), findsOneWidget);
      expect(find.text('server words'), findsNothing);
    });
  });

  group('once a block is done', () {
    testWidgets('tells the profile of the staff member the API answered with, and says so', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([StaffBlockWorking(active), StaffBlockIdle(blocked)]),
        initialState: StaffBlockIdle(active),
      );
      await pump(tester, StaffBlockIdle(active));
      await tester.pump();
      verify(() => profile.add(StaffProfileMemberChanged(blocked))).called(1);
      expect(find.text('Kavya Nair blocked'), findsOneWidget);
    });

    testWidgets('does the same for a lift, in its own words', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([StaffBlockWorking(blocked), StaffBlockIdle(active)]),
        initialState: StaffBlockIdle(blocked),
      );
      await pump(tester, StaffBlockIdle(blocked));
      await tester.pump();
      verify(() => profile.add(StaffProfileMemberChanged(active))).called(1);
      expect(find.text('Kavya Nair unblocked'), findsOneWidget);
    });

    testWidgets('tells the profile of the record read again when it was already as asked, with no word of success', (
      tester,
    ) async {
      whenListen(
        bloc,
        Stream.fromIterable([
          StaffBlockWorking(active),
          StaffBlockRefused(blocked, const ApiFailure(statusCode: 409, code: 'INVALID_STATE', message: 'x')),
        ]),
        initialState: StaffBlockIdle(active),
      );
      await pump(tester, StaffBlockIdle(active));
      await tester.pump();
      verify(() => profile.add(StaffProfileMemberChanged(blocked))).called(1);
      expect(find.text('Kavya Nair blocked'), findsNothing);
    });

    testWidgets('says nothing to the profile of a refusal', (tester) async {
      whenListen(
        bloc,
        Stream.fromIterable([
          StaffBlockWorking(active),
          StaffBlockRefused(active, const ApiFailure.network()),
        ]),
        initialState: StaffBlockIdle(active),
      );
      await pump(tester, StaffBlockIdle(active));
      await tester.pump();
      verifyNever(() => profile.add(any()));
    });
  });

  testWidgets('follows the record when someone else already blocked it: the status and the button change', (
    tester,
  ) async {
    final staff = MockStaffRepository();
    when(() => staff.block('f1')).thenThrow(const ApiFailure(statusCode: 409, code: 'INVALID_STATE', message: 'x'));
    when(() => staff.member('f1')).thenAnswer((_) async => blocked);
    final real = StaffBlockBloc(staff, active);
    addTearDown(real.close);
    await tester.pumpAppScaled(
      MultiBlocProvider(
        providers: [
          BlocProvider<StaffBlockBloc>.value(value: real),
          BlocProvider<StaffProfileBloc>.value(value: profile),
        ],
        child: const Scaffold(body: StaffSettingsView()),
      ),
    );
    await tester.tap(find.byKey(const Key('staffSettings.toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Dialog), matching: find.text('Block access')));
    await tester.pumpAndSettle();
    expect(find.text('Their access is already as you asked. The screen is up to date now.'), findsOneWidget);
    expect(find.textContaining('They are blocked.'), findsOneWidget);
    expect(find.text('Unblock access'), findsOneWidget);
    verify(() => profile.add(StaffProfileMemberChanged(blocked))).called(1);
  });

  testWidgets('reads whole at a large text scale on a small phone', (tester) async {
    await pump(tester, StaffBlockIdle(blocked), textScale: 2, size: const Size(320, 2000));
    expect(tester.takeException(), isNull);
    expect(clippedParagraphs(tester, unbreakable: 320 - 4 * 16), isEmpty);
  });
}
