import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/storage/accent_choice_store.dart';
import 'package:bravynix_school_erp/core/theme/app_colors.dart';
import 'package:equatable/equatable.dart';

sealed class AccentEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// The app opened: read the accent the person picked last.
final class AccentStarted extends AccentEvent {
  const new();
}

final class AccentChosen extends AccentEvent {
  const new(this.accent);

  final AppAccent accent;

  @override
  List<Object?> get props => [accent];
}

final class AccentState extends Equatable {
  const new(this.accent);

  final AppAccent accent;

  @override
  List<Object?> get props => [accent];
}

/// The accent colour of the whole app, above the router. Only the accent changes: neutrals, status and attendance
/// colours stay as they are (DESIGN_TOKENS.md).
class AccentBloc extends Bloc<AccentEvent, AccentState> {
  new(this._choice) : super(const AccentState(AppAccent.defaultAccent)) {
    on<AccentStarted>((event, emit) async {
      final remembered = await _choice.read();
      if (remembered != null) emit(AccentState(remembered));
    });
    on<AccentChosen>((event, emit) async {
      if (event.accent == state.accent) return;
      emit(AccentState(event.accent));
      await _choice.write(event.accent);
    });
  }

  final AccentChoiceStore _choice;
}
