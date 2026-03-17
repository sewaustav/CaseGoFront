import 'package:case_go/features/home/home_logic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── События ───────────────────────────────────────────────────────────────────

abstract class HomeEvent {}

class AppStarted extends HomeEvent {}

class LogoutRequested extends HomeEvent {}

/// Профиль успешно создан — переводим состояние в Authenticated
/// без лишнего запроса к серверу.
class ProfileSetupCompleted extends HomeEvent {}

// ── Состояния ─────────────────────────────────────────────────────────────────

abstract class HomeState {}

class HomeLoading extends HomeState {}

/// Авторизован и профиль заполнен — всё в порядке.
class Authenticated extends HomeState {
  final Map<String, dynamic> user;
  Authenticated(this.user);
}

/// Авторизован, но профиль ещё не заполнен.
/// Роутер/экран должен сделать редирект на /profile/setup.
class AuthenticatedNeedsProfile extends HomeState {
  final Map<String, dynamic> user;
  AuthenticatedNeedsProfile(this.user);
}

class Unauthenticated extends HomeState {}

// ── Блок ──────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;

  HomeBloc(this.repository) : super(HomeLoading()) {
    on<AppStarted>(_onAppStarted);
    on<LogoutRequested>(_onLogout);
    on<ProfileSetupCompleted>(_onProfileSetupCompleted);
  }

  Future<void> _onAppStarted(
      AppStarted event, Emitter<HomeState> emit) async {
    try {
      final result = await repository.checkAuth();
      if (result == null) {
        emit(Unauthenticated());
        return;
      }
      final (user, needsSetup) = result;
      if (needsSetup) {
        emit(AuthenticatedNeedsProfile(user));
      } else {
        emit(Authenticated(user));
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogout(
      LogoutRequested event, Emitter<HomeState> emit) async {
    await repository.logout();
    emit(Unauthenticated());
  }

  /// Профиль создан — переводим состояние без запроса к серверу.
  /// Роутер увидит Authenticated и перестанет редиректить на /profile/setup.
  Future<void> _onProfileSetupCompleted(
      ProfileSetupCompleted event, Emitter<HomeState> emit) async {
    final current = state;
    if (current is AuthenticatedNeedsProfile) {
      emit(Authenticated(current.user));
    }
  }
}