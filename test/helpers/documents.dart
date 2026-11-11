import 'package:bravynix_school_erp/features/documents/domain/document.dart';

/// A PDF kept with Kavya's record, added on 10 November 2026.
final appointmentLetter = Document(
  id: 'o1',
  title: 'Appointment letter',
  file: const DocumentFile(id: 'fl1', contentType: 'application/pdf', sizeBytes: 912, fileName: 'letter.pdf'),
  createdAt: DateTime.utc(2026, 11, 10, 10),
);

/// A picture of a certificate, 1.2 MB, added before the letter.
final degreeCertificate = Document(
  id: 'o2',
  title: 'B.Ed certificate',
  file: const DocumentFile(id: 'fl2', contentType: 'image/jpeg', sizeBytes: 1258291, fileName: 'bed.jpg'),
  createdAt: DateTime.utc(2026, 11, 9, 8),
);

Map<String, Object?> documentJson({
  String id = 'o1',
  String title = 'Appointment letter',
  String fileId = 'fl1',
  String contentType = 'application/pdf',
  int sizeBytes = 912,
  String fileName = 'letter.pdf',
  String createdAt = '2026-11-10T10:00:00.000Z',
}) => {
  'id': id,
  'ownerType': 'staff',
  'staffMemberId': 'f1',
  'title': title,
  'file': {'id': fileId, 'contentType': contentType, 'sizeBytes': sizeBytes, 'fileName': fileName},
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
  'createdAt': createdAt,
  'updatedBy': {'id': 'p1', 'displayName': 'A. Rao'},
  'updatedAt': createdAt,
};
