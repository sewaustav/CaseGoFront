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
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      // Вход в существующий аккаунт — isNewUser = false → идём на главную
      emit(AuthAuthenticated(user: user, isNewUser: false));
    } on AuthCancelledException {
      emit(AuthIdle(mode: _mode));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (e, st) {
      debugPrint('AuthBloc error: $e\n$st');
      emit(AuthError(message: 'Ошибка: $e', mode: _mode));
    }
  }

  Future<void> _onRegister(
      RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(AuthLoading(mode: _mode));
    try {
      final user = await _repository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      // Новый пользователь — isNewUser = true → идём заполнять профиль
      emit(AuthAuthenticated(user: user, isNewUser: true));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (_) {
      emit(AuthError(message: 'Неизвестная ошибка', mode: _mode));
    }
  }

  Future<void> _onGoogleSignIn(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(mode: _mode));
    try {
      final user = await _repository.loginWithGoogle();
      // Google Sign-In — редиректа нет (по ТЗ), просто остаёмся / обновляем стейт.
      // isNewUser = false, экран сам не делает go('/') — HomeBloc обновится
      // через AppStarted и роутер сделает редирект если нужно.
      emit(AuthAuthenticated(user: user, isNewUser: false));
    } on AuthCancelledException {
      emit(AuthIdle(mode: _mode));
    } on AuthFailureException catch (e) {
      emit(AuthError(message: e.message, mode: _mode));
    } catch (_) {
      emit(AuthError(message: 'Неизвестная ошибка', mode: _mode));
    }
  }

  void _onModeToggled(AuthModeToggled event, Emitter<AuthState> emit) {
    final next =
        _mode == AuthMode.login ? AuthMode.register : AuthMode.login;
    emit(AuthIdle(mode: next));
  }
}