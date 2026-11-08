import 'package:bravynix_school_erp/features/academic_years/domain/academic_year.dart';

const currentYear = AcademicYear(
  id: 'y1',
  institutionId: 'i1',
  name: '2026-2027',
  startDate: '2026-06-01',
  endDate: '2027-03-31',
  isCurrent: true,
  version: 2,
);

const earlierYear = AcademicYear(
  id: 'y0',
  institutionId: 'i1',
  name: '2025-2026',
  startDate: '2025-06-01',
  endDate: '2026-03-31',
  isCurrent: false,
  version: 4,
);

/// The same two years after the earlier one was made current.
const earlierYearMadeCurrent = AcademicYear(
  id: 'y0',
  institutionId: 'i1',
  name: '2025-2026',
  startDate: '2025-06-01',
  endDate: '2026-03-31',
  isCurrent: true,
  version: 5,
);

const currentYearDemoted = AcademicYear(
  id: 'y1',
  institutionId: 'i1',
  name: '2026-2027',
  startDate: '2026-06-01',
  endDate: '2027-03-31',
  isCurrent: false,
  version: 3,
);

Map<String, Object?> yearJson({
  String id = 'y1',
  String name = '2026-2027',
  String startDate = '2026-06-01',
  String endDate = '2027-03-31',
  bool isCurrent = true,
  int version = 2,
}) => {
  'id': id,
  'institutionId': 'i1',
  'name': name,
  'startDate': startDate,
  'endDate': endDate,
  'isCurrent': isCurrent,
  'status': 1,
  'version': version,
  'createdBy': {'id': 'p1', 'displayName': 'A. Rao'},
};
