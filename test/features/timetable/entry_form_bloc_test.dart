import 'package:bloc_test/bloc_test.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/core/paging/items_page.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:bravynix_school_erp/features/timetable/domain/timetable_entry.dart';
import 'package:bravynix_school_erp/features/timetable/presentation/bloc/entry_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';
import '../../helpers/staff.dart';
import '../../helpers/subjects.dart';
import '../../helpers/time_slots.dart';
import '../../helpers/timetable.dart';

void main() {
  late MockTimetableRepository timetable;
  late MockTimeSlotsRepository slots;
  late MockSubjectsRepository subjects;
  late MockStaffRepository staff;
  const options = EntryOptions(slots: [firstPeriod, lunch], subjects: [maths, art], teachers: [kavya]);

  setUpAll(() {
    registerFallbackValue(mathsMonday);
    registerFallbackValue(const EntryInput(dayOfWeek: 1, timeSlotId: 't1', isBreak: true));
  });
  setUp(() {
    timetable = MockTimetableRepository();
    slots = MockTimeSlotsRepository();
    subjects = MockSubjectsRepository();
    staff = MockStaffRepository();
    when(() => slots.slots('i1')).thenAnswer((_) async => [firstPeriod, lunch]);
    when(subjects.subjects).thenAnswer((_) async => [maths, art]);
    when(() => staff.staff('i1'))
        .thenAnswer((_) async => const ItemsPage<StaffSummary>([kavya, ravi], page: 1, totalPages: 1));
  });

  EntryFormBloc make({TimetableEntry? existing}) => EntryFormBloc(
    timetable,
    slots,
    subjects,
    staff,
    sectionId: 'sec1',
    institutionId: 'i1',
    existing: existing,
  );

  const lesson = EntryFields(dayOfWeek: 1, timeSlotId: 't1', subjectId: 'u1', staffMemberId: 'f1');
  const lessonInput = EntryInput(dayOfWeek: 1, timeSlotId: 't1', isBreak: false, subjectId: 'u1', staffMemberId: 'f1');

  group('reading what the form offers', () {
    blocTest<EntryFormBloc, EntryFormState>(
      'offers the periods, the subjects, and the staff who are not blocked',
      build: make,
      act: (bloc) => bloc.add(const EntryFormStarted()),
      expect: () => [const EntryFormLoading(), const EntryFormEditing(options)],
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'reads every page of the staff',
      build: make,
      setUp: () {
        when(() => staff.staff('i1'))
            .thenAnswer((_) async => const ItemsPage<StaffSummary>([ravi], page: 1, totalPages: 2));
        when(() => staff.staff('i1', page: 2))
            .thenAnswer((_) async => const ItemsPage<StaffSummary>([kavya], page: 2, totalPages: 2));
      },
      act: (bloc) => bloc.add(const EntryFormStarted()),
      expect: () => [const EntryFormLoading(), const EntryFormEditing(options)],
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'keeps why it could not read, and reads again on retry',
      build: make,
      setUp: () {
        var calls = 0;
        when(() => slots.slots('i1')).thenAnswer((_) async {
          if (++calls == 1) throw const ApiFailure(statusCode: 422, code: 'CURRENT_YEAR_REQUIRED', message: 'x');
          return [firstPeriod, lunch];
        });
      },
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormLoadFailed);
        bloc.add(const EntryFormStarted());
      },
      expect: () => [
        const EntryFormLoading(),
        const EntryFormLoadFailed(ApiFailure(statusCode: 422, code: 'CURRENT_YEAR_REQUIRED', message: 'x')),
        const EntryFormLoading(),
        const EntryFormEditing(options),
      ],
    );
  });

  group('saving', () {
    blocTest<EntryFormBloc, EntryFormState>(
      'adds a lesson to the section with TT-02',
      build: make,
      setUp: () => when(() => timetable.add('sec1', lessonInput)).thenAnswer((_) async => mathsMonday),
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc.add(const EntryFormSubmitted(lesson));
      },
      skip: 2,
      expect: () => [const EntryFormEditing(options, saving: true), const EntryFormSaved(mathsMonday)],
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'changes the entry it was opened on with TT-03',
      build: () => make(existing: mathsMonday),
      setUp: () => when(() => timetable.change(mathsMonday, lessonInput)).thenAnswer((_) async => mathsMonday),
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc.add(const EntryFormSubmitted(lesson));
      },
      skip: 2,
      expect: () => [const EntryFormEditing(options, saving: true), const EntryFormSaved(mathsMonday)],
      verify: (_) => verifyNever(() => timetable.add(any(), any())),
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'a break needs no subject and no teacher',
      build: make,
      setUp: () => when(
        () => timetable.add('sec1', const EntryInput(dayOfWeek: 2, timeSlotId: 't2', isBreak: true)),
      ).thenAnswer((_) async => lunchMonday),
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc.add(const EntryFormSubmitted(EntryFields(dayOfWeek: 2, timeSlotId: 't2', isBreak: true)));
      },
      skip: 2,
      expect: () => [const EntryFormEditing(options, saving: true), const EntryFormSaved(lunchMonday)],
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'names each choice a lesson lacks without sending anything',
      build: make,
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc.add(const EntryFormSubmitted(EntryFields()));
      },
      skip: 2,
      expect: () => [
        const EntryFormEditing(
          options,
          failure: ApiFailure.invalid([
            FieldError.required('dayOfWeek'),
            FieldError.required('timeSlotId'),
            FieldError.required('subjectId'),
            FieldError.required('staffMemberId'),
          ]),
        ),
      ],
      verify: (_) => verifyNever(() => timetable.add(any(), any())),
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'keeps the form open with the clash the server found',
      build: make,
      setUp: () => when(() => timetable.add('sec1', lessonInput)).thenThrow(
        const ApiFailure(statusCode: 409, code: 'SECTION_SLOT_TAKEN', message: 'x'),
      ),
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc.add(const EntryFormSubmitted(lesson));
      },
      skip: 2,
      expect: () => [
        const EntryFormEditing(options, saving: true),
        const EntryFormEditing(
          options,
          failure: ApiFailure(statusCode: 409, code: 'SECTION_SLOT_TAKEN', message: 'x'),
        ),
      ],
    );

    blocTest<EntryFormBloc, EntryFormState>(
      'ignores a second save while one is on its way',
      build: make,
      setUp: () => when(() => timetable.add('sec1', lessonInput)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return mathsMonday;
      }),
      act: (bloc) async {
        bloc.add(const EntryFormStarted());
        await bloc.stream.firstWhere((state) => state is EntryFormEditing);
        bloc
          ..add(const EntryFormSubmitted(lesson))
          ..add(const EntryFormSubmitted(lesson));
      },
      skip: 2,
      wait: const Duration(milliseconds: 50),
      expect: () => [const EntryFormEditing(options, saving: true), const EntryFormSaved(mathsMonday)],
      verify: (_) => verify(() => timetable.add('sec1', lessonInput)).called(1),
    );
  });
}
