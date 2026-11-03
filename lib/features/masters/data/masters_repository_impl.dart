import 'package:bravynix_school_erp/core/network/api_client.dart';
import 'package:bravynix_school_erp/features/masters/data/master_models.dart';
import 'package:bravynix_school_erp/features/masters/domain/master_entry.dart';
import 'package:bravynix_school_erp/features/masters/domain/masters_repository.dart';

class MastersRepositoryImpl implements MastersRepository {
  new({required this._api, this._clock = DateTime.now});

  final ApiClient _api;
  final DateTime Function() _clock;

  /// The answer carries `Cache-Control: private, max-age=300` (API design 10.4g).
  static const freshFor = Duration(minutes: 5);

  final Map<String, _Held> _held = {};

  @override
  Future<List<MasterEntry>> entries(MasterType type, {String? parentId}) async {
    final key = '${type.path}|${parentId ?? ''}';
    final held = _held[key];
    final now = _clock();
    if (held != null && now.difference(held.readAt) < freshFor) return held.entries;

    final parameter = type.parentParameter;
    final answer = await _api.conditional(
      'masters/${type.path}',
      parse: MasterModels.entries,
      etag: held?.etag,
      query: {?parameter: parentId},
    );
    // 304: what is held is still right, and counts as read now.
    final entries = answer.isModified ? answer.data! : held!.entries;
    _held[key] = _Held(entries, answer.isModified ? answer.etag : held!.etag, now);
    return entries;
  }
}

class _Held {
  const new(this.entries, this.etag, this.readAt);

  final List<MasterEntry> entries;
  final String? etag;
  final DateTime readAt;
}
