import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:case_go/features/profile_setup/profile_setup_repository.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class ProfileSetupEvent {}

class ProfileSetupSubmitted extends ProfileSetupEvent {
  final ProfileSetupMode mode;
  final ProfileSetupData data;

  ProfileSetupSubmitted({required this.mode, required this.data});
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class ProfileSetupState {}

class ProfileSetupIdle extends ProfileSetupState {}

class ProfileSetupLoading extends ProfileSetupState {}

class ProfileSetupSuccess extends ProfileSetupState {}

class ProfileSetupError extends ProfileSetupState {
  final String message;
  ProfileSetupError(this.message);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

class ProfileSetupBloc
    extends Bloc<ProfileSetupEvent, ProfileSetupState> {
  final ProfileSetupRepository _repository;

  ProfileSetupBloc(this._repository) : super(ProfileSetupIdle()) {
    on<ProfileSetupSubmitted>(_onSubmit);
  }

  Future<void> _onSubmit(
    ProfileSetupSubmitted event,
    Emitter<ProfileSetupState> emit,
  ) async {
    emit(ProfileSetupLoading());
    try {
      await _repository.submit(mode: event.mode, data: event.data);
      emit(ProfileSetupSuccess());
    } catch (e) {
      emit(ProfileSetupError('Ошибка: $e'));
    }
  }
}