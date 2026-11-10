import 'package:equatable/equatable.dart';

/// The place of an address as chosen from the shared lists: a state belongs to its country and a city to its state.
class PlaceChoice extends Equatable {
  const new({this.countryId, this.stateId, this.cityId});

  final String? countryId;
  final String? stateId;
  final String? cityId;

  @override
  List<Object?> get props => [countryId, stateId, cityId];
}
