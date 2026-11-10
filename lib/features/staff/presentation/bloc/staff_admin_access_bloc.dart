import 'package:bloc/bloc.dart';
import 'package:bravynix_school_erp/core/network/api_failure.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institution.dart';
import 'package:bravynix_school_erp/features/institutions/domain/institutions_repository.dart';
import 'package:bravynix_school_erp/features/staff/domain/staff_member.dart';
import 'package:equatable/equatable.dart';

sealed class StaffAdminAccessEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Opening the section, and Try again after a failure.
final class StaffAdminAccessStarted extends StaffAdminAccessEvent {
  const new();
}

/// Give the staff member Admin access to the Institution.
final class StaffAdminGranted extends StaffAdminAccessEvent {
  const new(this.institutionId);

  final String institutionId;

  @override
  List<Object?> get props => [institutionId];
}

/// Take the staff member's Admin access to the Institution away.
final class StaffAdminRevoked extends StaffAdminAccessEvent {
  const new(this.institutionId);

  final String institutionId;

  @override
  List<Object?> get props => [institutionId];
}

sealed class StaffAdminAccessState extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

class StaffAdminAccessLoading extends StaffAdminAccessState {
  const new();
}

class StaffAdminAccessFailed extends StaffAdminAccessState {
  const new(this.failure);

  final ApiFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// A grant or a revoke that went through, for the screen to say so.
class StaffAdminChange extends Equatable {
  const new(this.institutionId, {required this.granted});

  final String institutionId;

  /// True for a grant, false for a revoke.
  final bool granted;

  @override
  List<Object?> get props => [institutionId, granted];
}

/// The Institutions the person can be an Admin of (their own and their extra ones), and at which of them they are one.
class StaffAdminAccessReady extends StaffAdminAccessState {
  const new({required this.institutions, required this.adminAt, this.working, this.failure, this.failedAt, this.done});

  final List<InstitutionSummary> institutions;

  /// The IDs of the Institutions they hold Admin access to.
  final List<String> adminAt;

  /// The Institution a grant or a revoke is on its way for.
  final String? working;

  /// The last grant or revoke that was refused, and the Institution it was for.
  final ApiFailure? failure;
  final String? failedAt;

  /// The last grant or revoke that went through.
  final StaffAdminChange? done;

  StaffAdminAccessReady copyWith({
    List<String>? adminAt,
    String? Function()? working,
    ApiFailure? Function()? failure,
    String? Function()? failedAt,
    StaffAdminChange? Function()? done,
  }) => StaffAdminAccessReady(
    institutions: institutions,
    adminAt: adminAt ?? this.adminAt,
    working: working == null ? this.working : working(),
    failure: failure == null ? this.failure : failure(),
    failedAt: failedAt == null ? this.failedAt : failedAt(),
    done: done == null ? this.done : done(),
  );

  @override
  List<Object?> get props => [institutions, adminAt, working, failure, failedAt, done];
}

/// Admin access of one staff member (INS-08 to INS-10), for the Society Owner: who is an Admin of which of the
/// Institutions the person is at.
class StaffAdminAccessBloc extends Bloc<StaffAdminAccessEvent, StaffAdminAccessState> {
  new(this._institutions, {required this.member}) : super(const StaffAdminAccessLoading()) {
    on<StaffAdminAccessStarted>(_onStarted);
    on<StaffAdminGranted>((event, emit) => _change(event.institutionId, emit, grant: true));
    on<StaffAdminRevoked>((event, emit) => _change(event.institutionId, emit, grant: false));
  }

  final InstitutionsRepository _institutions;

  /// The staff member as the section was opened. A change of their extra Institutions opens it again.
  final StaffMember member;

  /// Whether the person holds Admin access to the Institution: the list is read a page at a time until they are in it.
  Future<bool> _holds(String institutionId) async {
    for (var page = 1; ; page++) {
      final admins = await _institutions.admins(institutionId, page: page);
      if (admins.items.any((admin) => admin.staffMemberId == member.id)) return true;
      if (!admins.hasMore) return false;
    }
  }

  Future<void> _onStarted(StaffAdminAccessStarted event, Emitter<StaffAdminAccessState> emit) async {
    emit(const StaffAdminAccessLoading());
    try {
      final reached = {member.homeInstitutionId, ...member.institutionIds};
      final institutions = [
        for (final institution in await _institutions.institutions())
          if (reached.contains(institution.id)) institution,
      ];
      final holds = await Future.wait([for (final institution in institutions) _holds(institution.id)]);
      emit(
        StaffAdminAccessReady(
          institutions: institutions,
          adminAt: [
            for (var i = 0; i < institutions.length; i++)
              if (holds[i]) institutions[i].id,
          ],
        ),
      );
    } on ApiFailure catch (failure) {
      emit(StaffAdminAccessFailed(failure));
    }
  }

  Future<void> _change(String institutionId, Emitter<StaffAdminAccessState> emit, {required bool grant}) async {
    if (state case final StaffAdminAccessReady ready when ready.working == null) {
      emit(ready.copyWith(working: () => institutionId, failure: () => null, failedAt: () => null, done: () => null));
      try {
        if (grant) {
          await _institutions.grantAdmin(institutionId, member.id);
        } else {
          await _institutions.revokeAdmin(institutionId, member.id);
        }
        if (state case final StaffAdminAccessReady now) {
          emit(
            now.copyWith(
              adminAt: _with(now.adminAt, institutionId, held: grant),
              working: () => null,
              done: () => StaffAdminChange(institutionId, granted: grant),
            ),
          );
        }
      } on ApiFailure catch (failure) {
        if (state case final StaffAdminAccessReady now) {
          emit(
            now.copyWith(
              // What the API says is the truth: already an Admin, or not one to take it from.
              adminAt: switch (failure.code) {
                'ALREADY_ADMIN' => _with(now.adminAt, institutionId, held: true),
                'NOT_FOUND' when !grant => _with(now.adminAt, institutionId, held: false),
                _ => null,
              },
              working: () => null,
              failure: () => failure,
              failedAt: () => institutionId,
            ),
          );
        }
      }
    }
  }

  static List<String> _with(List<String> ids, String id, {required bool held}) => [
    for (final other in ids)
      if (other != id) other,
    if (held) id,
  ];
}
