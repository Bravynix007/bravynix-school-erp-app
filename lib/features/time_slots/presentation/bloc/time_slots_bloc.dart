import 'package:bravynix_school_erp/core/bloc/list_bloc.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slot.dart';
import 'package:bravynix_school_erp/features/time_slots/domain/time_slots_repository.dart';

final class TimeSlotDeactivated extends ListEvent {
  const new(this.slot);

  final TimeSlot slot;

  @override
  List<Object?> get props => [slot];
}

/// The periods of one Institution's current year (TTS-01), and deactivating one (TTS-04).
class TimeSlotsBloc extends ListBloc<TimeSlot> {
  new(this._slots, this.institutionId) {
    on<TimeSlotDeactivated>(
      (event, emit) => change(emit, event.slot, event.slot.id, () => _slots.deactivate(event.slot.id)),
    );
  }

  final TimeSlotsRepository _slots;
  final String institutionId;

  @override
  Future<List<TimeSlot>> read() => _slots.slots(institutionId);
}
