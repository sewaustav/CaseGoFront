import 'package:case_go/core/api/admin/admin.dart';
import 'package:case_go/core/api/cases/cases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ────────────────────────────────────────────────────────────────────

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<Map<String, dynamic>> cases;
  final List<Map<String, dynamic>> users;
  final Map<String, dynamic>? stats;

  AdminLoaded({
    required this.cases,
    required this.users,
    this.stats,
  });

  AdminLoaded copyWith({
    List<Map<String, dynamic>>? cases,
    List<Map<String, dynamic>>? users,
    Map<String, dynamic>? stats,
  }) =>
      AdminLoaded(
        cases: cases ?? this.cases,
        users: users ?? this.users,
        stats: stats ?? this.stats,
      );
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class AdminCubit extends Cubit<AdminState> {
  final CaseGoApi _caseApi;
  final AdminApi _adminApi;

  AdminCubit(this._caseApi, this._adminApi) : super(AdminInitial());

  Future<void> load() async {
    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _caseApi.getCases(limit: 100, page: 1),
        _adminApi.getUsers(),
        _caseApi.getStats(),
      ]);
      emit(AdminLoaded(
        cases: results[0] as List<Map<String, dynamic>>,
        users: results[1] as List<Map<String, dynamic>>,
        stats: results[2] as Map<String, dynamic>,
      ));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> createCase(Map<String, dynamic> body) async {
    try {
      await _caseApi.createCase(body);
      await load();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateCase(int caseId, Map<String, dynamic> body) async {
    try {
      await _caseApi.updateCase(caseId, body);
      await load();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> deleteCase(int caseId) async {
    try {
      await _caseApi.deleteCase(caseId);
      await load();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  Future<void> updateUserRole(int userId, int role) async {
    try {
      await _adminApi.updateUserRole(userId, role);
      await load();
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
}
