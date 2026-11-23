import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/format/formatters.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_day.dart';
import 'package:bravynix_school_erp/features/sections/domain/section_options.dart';
import 'package:equatable/equatable.dart';

sealed class SectionDayEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the screen, and Try again after the classes could not be read.
final class SectionDayStarted extends SectionDayEvent {
  const new();
}

/// Another class chosen: its section has to be chosen too, unless it has only one.
final class SectionDayClassChosen extends SectionDayEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

final class SectionDaySectionChosen extends SectionDayEvent {
  const new(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// Another day, `YYYY-MM-DD`.
final class SectionDayDayChosen extends SectionDayEvent {
  const new(this.day);

  final String day;

  @override
  List<Object?> get props => [day];
}

sealed class SectionDayState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class SectionDayLoading extends SectionDayState {
  const new();
}

/// The classes could not be read.
class SectionDayFailed extends SectionDayState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The classes and sections to choose from (none when only the day is chosen), and what is chosen.
class SectionDayReady extends SectionDayState {
  const new({
    required this.classes,
    required this.sections,
    required this.today,
    required this.day,
    this.classId,
    this.sectionId,
  });

  final List<ClassChoice> classes;
  final List<SectionChoice> sections;

  /// The school day (IST), `YYYY-MM-DD`: the last day that can be chosen.
  final String today;

  /// `YYYY-MM-DD`.
  final String day;
  final String? classId;
  final String? sectionId;

  List<SectionChoice> get sectionsInClass => sections.inClass(classId);

  /// The section and day chosen; null while no section is.
  SectionDay? get selection => sectionId == null ? null : SectionDay(sectionId: sectionId!, day: day);

  SectionDayReady copyWith({String? Function()? classId, String? Function()? sectionId, String? day}) =>
      SectionDayReady(
        classes: classes,
        sections: sections,
        today: today,
        day: day ?? this.day,
        classId: classId == null ? this.classId : classId(),
        sectionId: sectionId == null ? this.sectionId : sectionId(),
      );

  @override
  List<Object?> get props => [classes, sections, today, day, classId, sectionId];
}

/// The class, section and day a screen that reads a section's day chooses (attendance, the diary). The loader gives the
/// classes and sections the person may choose from; a school with one class and one section has nothing to choose, and
/// a focus that names a section of the list opens on it.
class SectionDayBloc extends Bloc<SectionDayEvent, SectionDayState> {
  new(this._load, {this._clock = DateTime.now, this.focus, this.startDay}) : super(const SectionDayLoading()) {
    on<SectionDayStarted>(_onStarted);
    on<SectionDayClassChosen>(_onClassChosen);
    on<SectionDaySectionChosen>(_onSectionChosen);
    on<SectionDayDayChosen>(_onDayChosen);
  }

  /// A screen that chooses the day only, such as a parent's diary of the child shown.
  new dayOnly({DateTime Function() clock = DateTime.now, String? day}) : this(_noSections, clock: clock, startDay: day);

  final Future<SectionChoices> Function() _load;
  final DateTime Function() _clock;
  final SectionDay? focus;

  /// The day to open on when there is no [focus] (`YYYY-MM-DD`), when it is a real day and not after today, which
  /// cannot be chosen; today otherwise (a route can carry anything).
  final String? startDay;

  static Future<SectionChoices> _noSections() async =>
      (classes: const <ClassChoice>[], sections: const <SectionChoice>[]);

  Future<void> _onStarted(SectionDayStarted event, Emitter<SectionDayState> emit) async {
    emit(const SectionDayLoading());
    try {
      final choices = await _load();
      final today = Formatters.schoolDay(_clock());
      final target = choices.sections.where((section) => section.id == focus?.sectionId).firstOrNull;
      final single = choices.classes.length == 1 ? choices.classes.single.id : null;
      final ready = SectionDayReady(
        classes: choices.classes,
        sections: choices.sections,
        today: today,
        day: target != null ? focus!.day : (_opensOn(startDay, today) ? startDay! : today),
        classId: target?.classId ?? single,
        sectionId: target?.id,
      );
      emit(target == null ? _withOnlySection(ready) : ready);
    } on ApiFailure catch (failure) {
      emit(SectionDayFailed(failure));
    }
  }

  /// Whether [day] is a real day (`2026-02-30` and `1` are not) that is not after [today].
  static bool _opensOn(String? day, String today) {
    final parsed = day == null ? null : Formatters.parseDay(day);
    return parsed != null && Formatters.isoDay(parsed) == day && day!.compareTo(today) <= 0;
  }

  /// A class with one section has nothing more to choose.
  static SectionDayReady _withOnlySection(SectionDayReady ready) {
    final only = ready.sectionsInClass;
    return only.length == 1 ? ready.copyWith(sectionId: () => only.single.id) : ready;
  }

  void _onClassChosen(SectionDayClassChosen event, Emitter<SectionDayState> emit) {
    if (state case final SectionDayReady ready when event.id != null && event.id != ready.classId) {
      emit(_withOnlySection(ready.copyWith(classId: () => event.id, sectionId: () => null)));
    }
  }

  void _onSectionChosen(SectionDaySectionChosen event, Emitter<SectionDayState> emit) {
    if (state case final SectionDayReady ready when event.id != null && event.id != ready.sectionId) {
      emit(ready.copyWith(sectionId: () => event.id));
    }
  }

  void _onDayChosen(SectionDayDayChosen event, Emitter<SectionDayState> emit) {
    if (state case final SectionDayReady ready when event.day != ready.day) emit(ready.copyWith(day: event.day));
  }
}
