import 'dart:async';

abstract class ProfileApi {
  /// POST /profile — создать профиль (после регистрации)
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> body);

  /// GET /profile — получить свой профиль
  Future<Map<String, dynamic>> getProfile();

  /// PUT /profile — полное обновление профиля
  Future<Map<String, dynamic>> replaceProfile(Map<String, dynamic> body);

  /// PATCH /profile — частичное обновление профиля
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body);

  /// DELETE /profile — мягкое удаление
  Future<void> deleteProfile();

  /// POST /profile/social — добавить соцсети
  Future<Map<String, dynamic>> createSocialLink(Map<String, dynamic> body);

  /// PUT /profile/social/{id}
  Future<Map<String, dynamic>> replaceSocialLink(int id, Map<String, dynamic> body);

  /// DELETE /profile/social/{id}
  Future<void> deleteSocialLink(int id);

  /// POST /profile/purpose — добавить цели
  Future<Map<String, dynamic>> createPurpose(Map<String, dynamic> body);

  /// PUT /profile/purpose/{id}
  Future<Map<String, dynamic>> replacePurpose(int id, Map<String, dynamic> body);

  /// DELETE /profile/purpose/{id}
  Future<void> deletePurpose(int id);

  /// POST /profession
  Future<Map<String, dynamic>> createProfession(Map<String, dynamic> body);

  /// GET /profession
  Future<List<Map<String, dynamic>>> getProfessions();

  /// PUT /profession/{id}
  Future<Map<String, dynamic>> replaceProfession(int id, Map<String, dynamic> body);

  /// DELETE /profession/{id}
  Future<void> deleteProfession(int id);
}