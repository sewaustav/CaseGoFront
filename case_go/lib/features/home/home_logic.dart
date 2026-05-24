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
    final level = await _authRepository.getProfileLevel();
    return ({
      'id': user.id,
      'email': user.email,
      'username': user.name,
      'role': user.role,
      'xp': level?['xp'] as int? ?? 0,
      'streak': level?['streak'] as int? ?? 0,
      'level': level?['level'] as int? ?? 1,
    }, needsSetup);
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  /// Обновляет только xp/level/streak для уже авторизованного пользователя.
  Future<Map<String, dynamic>?> getLevel() async {
    return _authRepository.getProfileLevel();
  }
}