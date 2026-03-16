import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:case_go/features/auth/models/auth_user.dart';
import 'package:case_go/features/auth/models/auth_exception.dart';
import 'package:case_go/features/auth/repository/auth_repo.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(const AuthIdle()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AuthModeToggled>(_onModeToggled);
  }

  AuthMode get _mode => switch (state) {
        AuthIdle(:final mode) => mode,
        AuthLoading(:final mode) => mode,
        AuthError(:final mode) => mode,
        _ => AuthMode.login,
      };

  Future<void> _onLogin(
      LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading(mode: _mode));
    try {
      final (user, needsSetup) = await _repository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user, needsProfileSetup: needsSetup));
    } on AuthCancelledException {
      emit(AuthIdle(mode: _mode));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (e, st) {
      debugPrint('AuthBloc._onLogin error: $e\n$st');
      emit(AuthError(message: 'Ошибка: $e', mode: _mode));
    }
  }

  Future<void> _onRegister(
      RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading(mode: _mode));
    try {
      final (user, needsSetup) = await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user, needsProfileSetup: needsSetup));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (e) {
      emit(AuthError(message: 'Неизвестная ошибка: $e', mode: _mode));
    }
  }

  Future<void> _onGoogleSignIn(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(mode: _mode));
    try {
      final (user, needsSetup) = await _repository.loginWithGoogle();
      emit(AuthAuthenticated(user: user, needsProfileSetup: needsSetup));
    } on AuthCancelledException {
      emit(AuthIdle(mode: _mode));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (e) {
      emit(AuthError(message: 'Неизвестная ошибка: $e', mode: _mode));
    }
  }

  void _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) {
    final next =
        _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    emit(AuthIdle(mode: next));
  }
}