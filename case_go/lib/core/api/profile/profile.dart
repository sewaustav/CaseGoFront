import 'dart:async';

/// Абстрактный класс, описывающий API управления профилем пользователя.
///
/// Покрывает следующие эндпоинты:
/// - POST   /profile
/// - GET    /profile
/// - PUT    /profile
/// - PATCH  /profile
/// - DELETE /profile
/// - POST   /social
/// - PUT    /social/{id}
/// - DELETE /social/{id}
/// - POST   /purpose
/// - PUT    /purpose/{id}
/// - DELETE /purpose/{id}
/// - POST   /profession
/// - GET    /profession
/// - PUT    /profession/{id}
/// - DELETE /profession/{id}
/// - GET    /profession_categories
/// - GET    /search
/// - GET    /search/fio
abstract class ProfileApi {
  // ──────────────────────────────────────────
  // Профиль
  // ──────────────────────────────────────────

  /// Создаёт профиль текущего пользователя.
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> body);

  /// Возвращает профиль текущего пользователя.
  Future<Map<String, dynamic>> getProfile();

  /// Полностью заменяет профиль текущего пользователя.
  Future<Map<String, dynamic>> replaceProfile(Map<String, dynamic> body);

  /// Частично обновляет профиль текущего пользователя.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body);

  /// Удаляет профиль текущего пользователя.
  Future<void> deleteProfile();

  // ──────────────────────────────────────────
  // Социальные ссылки
  // ──────────────────────────────────────────

  /// Добавляет социальную ссылку.
  Future<Map<String, dynamic>> createSocialLink(Map<String, dynamic> body);

  /// Полностью заменяет социальную ссылку по [id].
  Future<Map<String, dynamic>> replaceSocialLink(
    int id,
    Map<String, dynamic> body,
  );

  /// Удаляет социальную ссылку по [id].
  Future<void> deleteSocialLink(int id);

  // ──────────────────────────────────────────
  // Цели пользователя
  // ──────────────────────────────────────────

  /// Добавляет цель пользователя.
  Future<Map<String, dynamic>> createPurpose(Map<String, dynamic> body);

  /// Полностью заменяет цель пользователя по [id].
  Future<Map<String, dynamic>> replacePurpose(
    int id,
    Map<String, dynamic> body,
  );

  /// Удаляет цель пользователя по [id].
  Future<void> deletePurpose(int id);

  // ──────────────────────────────────────────
  // Профессии
  // ──────────────────────────────────────────

  /// Добавляет профессию для поиска.
  Future<Map<String, dynamic>> createProfession(Map<String, dynamic> body);

  /// Возвращает список профессий текущего пользователя.
  Future<List<Map<String, dynamic>>> getProfessions();

  /// Полностью заменяет профессию по [id].
  Future<Map<String, dynamic>> replaceProfession(
    int id,
    Map<String, dynamic> body,
  );

  /// Удаляет профессию по [id].
  Future<void> deleteProfession(int id);

  // ──────────────────────────────────────────
  // Категории профессий
  // ──────────────────────────────────────────

  /// Возвращает список категорий профессий.
  Future<List<Map<String, dynamic>>> getProfessionCategories();

  // ──────────────────────────────────────────
  // Поиск
  // ──────────────────────────────────────────

  /// Выполняет поиск пользователей по произвольным параметрам.
  ///
  /// [queryParams] — набор фильтров (например, `city`, `profession` и т.д.).
  Future<List<Map<String, dynamic>>> search(Map<String, String> queryParams);

  /// Выполняет поиск пользователей по ФИО.
  ///
  /// [fio] — строка с именем или его частью.
  Future<List<Map<String, dynamic>>> searchByFio(String fio);
}