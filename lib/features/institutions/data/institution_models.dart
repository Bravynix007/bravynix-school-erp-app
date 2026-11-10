import 'package:bravynix_school_erp/core/model/phone.dart';
import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';

/// JSON → domain for INS-01 and INS-03. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class InstitutionModels {
  static InstitutionSummary summary(Object? raw) {
    final json = jsonObject(raw);
    return InstitutionSummary(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      place: json['place'] as String?,
      board: Board.fromCode(json['boardCode']),
    );
  }

  static List<InstitutionSummary> summaries(Object? raw) => [for (final item in jsonList(raw)) summary(item)];

  static Institution institution(Object? raw) {
    final json = jsonObject(raw);
    final address = jsonObject(json['address']);
    return Institution(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      version: (json['version'] as num).toInt(),
      place: json['place'] as String?,
      board: Board.fromCode(json['boardCode']),
      affiliationNumber: json['affiliationNumber'] as String?,
      gstin: json['gstin'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] == null ? null : Phone.fromJson(json['phone']),
      telephone: json['telephone'] as String?,
      addressLine1: address['line1'] as String,
      addressLine2: address['line2'] as String?,
      pincode: address['pincode'] as String?,
      countryId: address['countryId'] as String?,
      stateId: address['stateId'] as String?,
      cityId: address['cityId'] as String?,
      classesOffered: [
        for (final item in jsonList(json['classesOffered']))
          OfferedCategory(id: jsonObject(item)['id'] as String, name: jsonObject(item)['name'] as String),
      ],
    );
  }

  /// INS-02: what is set is sent; what is empty is left out.
  static Map<String, Object?> createBody(InstitutionDraft draft) => {
    'name': draft.name,
    'code': draft.code,
    'classesOffered': draft.classesOffered,
    ..._profile(draft, clearing: false),
  };

  /// INS-04: every editable field, with `null` for what the form left empty, so clearing a field clears it. The
  /// address and the phone are replaced as a whole; the code is never sent.
  static Map<String, Object?> updateBody(InstitutionDraft draft, int version) => {
    'version': version,
    'name': draft.name,
    'classesOffered': draft.classesOffered,
    ..._profile(draft, clearing: true),
  };

  static Map<String, Object?> _profile(InstitutionDraft draft, {required bool clearing}) {
    Map<String, Object?> optional(Map<String, Object?> fields) => {
      for (final entry in fields.entries)
        if (clearing || entry.value != null) entry.key: entry.value,
    };
    return {
      ...optional({
        'place': draft.place,
        'boardCode': draft.board?.code,
        'affiliationNumber': draft.affiliationNumber,
        'gstin': draft.gstin,
        'email': draft.email,
        'telephone': draft.telephone,
        'phone': draft.phone?.toJson(),
      }),
      'address': {
        'line1': draft.addressLine1,
        ...optional({
          'line2': draft.addressLine2,
          'pincode': draft.pincode,
          'countryId': draft.countryId,
          'stateId': draft.stateId,
          'cityId': draft.cityId,
        }),
      },
    };
  }
}
