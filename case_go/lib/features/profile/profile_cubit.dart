import 'package:case_go/core/api/case_profile/case_profile.dart';
import 'package:case_go/core/api/profile/profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ─────────────────────────────────────────────────────────────────────

abstract class ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> purposes;
  final List<Map<String, dynamic>> socials;
  final Map<String, dynamic>? skills;
  final List<Map<String, dynamic>> history;
  final bool chartsVisible;

  ProfileLoaded({
    required this.profile,
    required this.purposes,
    required this.socials,
    this.skills,
    this.history = const [],
    this.chartsVisible = false,
  });

  ProfileLoaded copyWith({
    Map<String, dynamic>? skills,
    List<Map<String, dynamic>>? history,
    bool? chartsVisible,
  }) =>
      ProfileLoaded(
        profile: profile,
        purposes: purposes,
        socials: socials,
        skills: skills ?? this.skills,
        history: history ?? this.history,
        chartsVisible: chartsVisible ?? this.chartsVisible,
      );
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileApi _profileApi;
  final CaseProfileApi _caseProfileApi;

  ProfileCubit(this._profileApi, this._caseProfileApi)
      : super(ProfileLoading());

  Future<void> load() async {
    emit(ProfileLoading());
    try {
      final raw = await _profileApi.getProfile();
      final profile =
          (raw['UsrProfile'] ?? raw) as Map<String, dynamic>;
      final purposes = ((raw['UsrPurposes'] ?? []) as List)
          .cast<Map<String, dynamic>>();
      final socials = ((raw['UsrSocials'] ?? []) as List)
          .cast<Map<String, dynamic>>();
      emit(ProfileLoaded(
          profile: profile, purposes: purposes, socials: socials));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> toggleCharts() async {
    final current = state;
    if (current is! ProfileLoaded) return;

    if (current.chartsVisible) {
      emit(current.copyWith(chartsVisible: false));
      return;
    }

    // Load skills + history if not yet loaded
    try {
      final skills = current.skills ??
          await _caseProfileApi.getSkillsProfile();
      final history = current.history.isEmpty
          ? await _caseProfileApi.getHistory()
          : current.history;
      emit(current.copyWith(
        skills: skills,
        history: history,
        chartsVisible: true,
      ));
    } catch (_) {
      emit(current.copyWith(chartsVisible: true));
    }
  }
}
