import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/auth/domain/auth_entities.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/cubit/society_blocks_cubit.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/blocked_access_notice.dart';
import 'package:bravynix_school_erp/features/blocks/presentation/view/society_blocks_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clipped_text.dart';
import '../../helpers/pump_app.dart';

class _MockBlocksCubit extends MockCubit<SocietyBlocksState> implements SocietyBlocksCubit;

void main() {
  late _MockBlocksCubit cubit;
  setUp(() => cubit = _MockBlocksCubit());

  final owners = SectionBlock(
    id: 'b1',
    section: BlockSection.owners,
    reason: 'Terms not accepted',
    blockedAt: DateTime.utc(2026, 10, 27, 4, 30),
  );
  final staff = SectionBlock(
    id: 'b2',
    section: BlockSection.staff,
    institutionId: 'i1',
    institutionName: 'Sri Vidya High School',
    reason: 'Annual fee unpaid',
    blockedAt: DateTime.utc(2026, 10, 27, 5),
  );
  final students = SectionBlock(
    id: 'b3',
    section: BlockSection.students,
    institutionId: 'i1',
    institutionName: 'Sri Vidya High School',
    reason: 'Annual fee unpaid',
    blockedAt: DateTime.utc(2026, 10, 27, 6),
  );

  Future<void> pump(WidgetTester tester, SocietyBlocksState state, {double textScale = 1}) {
    when(() => cubit.state).thenReturn(state);
    return tester.pumpAppScaled(
      BlocProvider<SocietyBlocksCubit>.value(
        value: cubit,
        child: const Scaffold(
          body: SingleChildScrollView(child: SocietyBlocksView(societyName: 'Sunrise Trust')),
        ),
      ),
      textScale: textScale,
    );
  }

  group('SocietyBlocksView', () {
    testWidgets('shows each block with what it stops, the reason and when', (tester) async {
      await pump(tester, SocietyBlocksLoaded([owners, staff, students]));
      expect(find.text('Blocked in Sunrise Trust'), findsOneWidget);
      expect(find.text('Owners'), findsOneWidget);
      expect(find.text('Staff of Sri Vidya High School'), findsOneWidget);
      expect(find.text('Parents of Sri Vidya High School'), findsOneWidget);
      expect(find.text('Reason: Terms not accepted'), findsOneWidget);
      expect(find.text('Reason: Annual fee unpaid'), findsNWidgets(2));
      // 04:30 UTC is 10:00 in India.
      expect(find.text('Blocked on 27-10-2026 10:00'), findsOneWidget);
    });

    testWidgets('shows nothing while nothing is blocked, and while it loads', (tester) async {
      await pump(tester, const SocietyBlocksLoaded([]));
      expect(find.byType(Text), findsNothing);
      await pump(tester, const SocietyBlocksLoading());
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('says it could not load, and loads again on Try again', (tester) async {
      when(() => cubit.load()).thenAnswer((_) async {});
      await pump(tester, const SocietyBlocksFailed(ApiFailure.network()));
      expect(find.text("Can't reach the server. Check your connection and try again."), findsOneWidget);
      await tester.tap(find.byKey(const Key('blocks.retry')));
      verify(() => cubit.load()).called(1);
    });

    testWidgets('reads whole at a large text scale on a small phone', (tester) async {
      await pump(tester, SocietyBlocksLoaded([owners, staff]), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(clippedParagraphs(tester), isEmpty);
    });
  });

  group('BlockedAccessNotice', () {
    Future<void> pumpNotice(WidgetTester tester, AuthContext active) =>
        tester.pumpApp(Scaffold(body: BlockedAccessNotice(active: active)));

    testWidgets('sends a blocked Owner to BravyNix support', (tester) async {
      await pumpNotice(
        tester,
        const AuthContext(role: RoleCode.societyOwner, societyName: 'Sunrise Trust', isBlocked: true),
      );
      expect(find.text('Access to Sunrise Trust is blocked. Contact BravyNix support.'), findsOneWidget);
    });

    testWidgets('sends blocked staff to their Society', (tester) async {
      for (final role in [RoleCode.institutionAdmin, RoleCode.teacherStaff]) {
        await pumpNotice(tester, AuthContext(role: role, societyName: 'Sunrise Trust', isBlocked: true));
        expect(find.text('Your access to Sunrise Trust is blocked. Contact your Society.'), findsOneWidget);
      }
    });

    testWidgets('sends a blocked parent to the school', (tester) async {
      await pumpNotice(tester, const AuthContext(role: RoleCode.studentParent, isBlocked: true));
      expect(find.text("Access to your children's information is blocked. Contact the school."), findsOneWidget);
    });

    testWidgets('says nothing for a role that is not blocked', (tester) async {
      await pumpNotice(tester, const AuthContext(role: RoleCode.societyOwner, societyName: 'Sunrise Trust'));
      expect(find.byType(Text), findsNothing);
    });
  });
}
