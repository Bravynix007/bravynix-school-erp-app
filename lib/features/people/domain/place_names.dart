import 'package:bravynix_school_erp/core/model/address.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_names.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';
import 'package:equatable/equatable.dart';

/// The names of the country, state and city an [Address] holds the IDs of, as a profile shows them. Each is null when
/// the address has none, or the master no longer shows it.
class PlaceNames extends Equatable {
  const new({this.country, this.state, this.city});

  final String? country;
  final String? state;
  final String? city;

  @override
  List<Object?> get props => [country, state, city];
}

extension PlaceNamesReader on MastersRepository {
  /// The names of the places of [address]. A city is looked for only under a state, as the master lists them.
  Future<PlaceNames> placeNamesOf(Address address) async => PlaceNames(
    country: await nameOf(MasterType.countries, address.countryId),
    state: await nameOf(MasterType.states, address.stateId, parentId: address.countryId),
    city: address.stateId == null ? null : await nameOf(MasterType.cities, address.cityId, parentId: address.stateId),
  );
}
