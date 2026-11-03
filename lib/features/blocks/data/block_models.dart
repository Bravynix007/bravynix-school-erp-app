import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';

/// JSON → domain for SOC-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class BlockModels {
  static SectionBlock block(Object? raw) {
    final json = jsonObject(raw);
    final section = BlockSection.fromName(json['section']);
    if (section == null) throw FormatException('Unknown block section ${json['section']}');
    return SectionBlock(
      id: json['id'] as String,
      section: section,
      institutionId: json['institutionId'] as String?,
      institutionName: json['institutionName'] as String?,
      reason: json['reason'] as String,
      blockedAt: DateTime.parse(json['blockedAt'] as String),
    );
  }

  static List<SectionBlock> blocks(Object? json) => [for (final item in jsonList(json)) block(item)];
}
