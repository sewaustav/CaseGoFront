import 'package:case_go/features/auth/repository/auth_repo.dart';

class HomeRepository {
  final AuthRepository _authRepository;

  HomeRepository(this._authRepository);

  /// Проверяет сессию при старте приложения.
  ///
  /// Возвращает:
  /// - (user, needsProfileSetup) если есть токен
  /// - null если пользователь не авторизован
  Future<(Map<String, dynamic>, bool)?> checkAuth() async {
    final result = await _authRepository.restoreSession();
    if (result == null) return null;

    final (user, needsSetup) = result;
    return ({'id': user.id, 'email': user.email, 'username': user.name}, needsSetup);
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }
}