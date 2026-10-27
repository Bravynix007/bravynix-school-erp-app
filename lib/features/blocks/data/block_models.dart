import 'package:bravynix_school_erp/features/blocks/domain/section_block.dart';

/// JSON → domain for SOC-02. Unknown fields are ignored, as /v1 only ever adds fields (API design 5.2).
abstract final class BlockModels {
  static SectionBlock block(Object? json) {
    if (json is! Map<String, dynamic>) throw const FormatException('Expected a JSON object');
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

  static List<SectionBlock> blocks(Object? json) => json is List<dynamic>
      ? [for (final item in json) block(item)]
      : throw const FormatException('Expected a JSON array');
}
