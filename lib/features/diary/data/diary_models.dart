import 'package:bravynix_school_erp/core/network/json_shape.dart';
import 'package:bravynix_school_erp/features/diary/domain/diary_entry.dart';

/// JSON → domain for DIA-01 to DIA-03, and domain → body. Unknown fields are ignored, as /v1 only ever adds fields (API
/// design 5.2).
abstract final class DiaryModels {
  static DiaryEntry entry(Object? raw) {
    final json = jsonObject(raw);
    final subject = jsonObject(json['subject']);
    final teacher = json['teacher'] == null ? null : jsonObject(json['teacher']);
    return DiaryEntry(
      id: json['id'] as String,
      version: (json['version'] as num).toInt(),
      sectionId: json['sectionId'] as String,
      subjectId: subject['id'] as String,
      subjectName: subject['name'] as String,
      day: json['diaryDate'] as String,
      description: json['description'] as String,
      teacherId: teacher?['id'] as String?,
      teacherName: teacher?['displayName'] as String?,
    );
  }

  static List<DiaryEntry> entries(Object? raw) => [for (final item in jsonList(raw)) entry(item)];

  static Map<String, Object?> createBody(String sectionId, DiaryInput input) => {
    'sectionId': sectionId,
    'subjectId': input.subjectId,
    'diaryDate': input.day,
    'description': input.description,
  };

  /// The version that was read, and only the fields that differ, so a date that was not touched is not checked again.
  static Map<String, Object?> changeBody(DiaryEntry entry, DiaryInput input) => {
    'version': entry.version,
    if (input.subjectId != entry.subjectId) 'subjectId': input.subjectId,
    if (input.day != entry.day) 'diaryDate': input.day,
    if (input.description != entry.description) 'description': input.description,
  };
}
