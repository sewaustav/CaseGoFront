import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';
import 'package:flutter/foundation.dart';

/// Репозиторий, изолирует логику отправки профиля от UI.
/// Знает только о своём модуле — не тянет зависимости из других фич.
class ProfileSetupRepository {
  final ProfileApi _api;

  ProfileSetupRepository(this._api);

  /// Отправляет профиль в зависимости от режима:
  /// - [ProfileSetupMode.create] → POST /profile (тело: CreateProfileRequest)
  /// - [ProfileSetupMode.edit]   → PATCH /profile (тело: UpdateProfilePartialDTO)
  Future<void> submit({
    required ProfileSetupMode mode,
    required ProfileSetupData data,
  }) async {
    switch (mode) {
      case ProfileSetupMode.create:
        await _api.createProfile(data.toCreateRequest());
      case ProfileSetupMode.edit:
        await _api.updateProfile(data.toPartialUpdateRequest());
    }
  }
}

/// Данные формы профиля.
/// Маппит пользовательский ввод в тела запросов бэкенда.
class ProfileSetupData {
  final String username;
  final String name;
  final String surname;
  final String? patronymic;
  final String? city;
  final int? age;
  final int? sex; // 0 или 1
  final String description;
  final String? profession;
  final List<String> purposes; // минимум 1
  final List<SocialLinkData> socialLinks;

  const ProfileSetupData({
    required this.username,
    required this.name,
    required this.surname,
    this.patronymic,
    this.city,
    this.age,
    this.sex,
    this.description = '',
    this.profession,
    required this.purposes,
    this.socialLinks = const [],
  });

  /// POST /profile — CreateProfileRequest
  Map<String, dynamic> toCreateRequest() => {
        'info': {
          // avatar обязателен на бэке, но загрузка файлов не реализована.
          // Отправляем пустую строку — бэкенд должен обрабатывать это gracefully,
          // либо позже добавим upload.
          'avatar': '',
          'username': username,
          'name': name,
          'surname': surname,
          if (patronymic != null) 'patronymic': patronymic,
          if (city != null) 'city': city,
          if (age != null) 'age': age,
          if (sex != null) 'sex': sex,
          'description': description,
          if (profession != null) 'profession': profession,
        },
        'purposes': purposes.map((p) => {'purpose': p}).toList(),
        'social_links':
            socialLinks.map((l) => {'type': l.type, 'url': l.url}).toList(),
      };

  /// PATCH /profile — UpdateProfilePartialDTO
  /// Отправляем только непустые поля
  Map<String, dynamic> toPartialUpdateRequest() => {
        if (username.isNotEmpty) 'username': username,
        if (name.isNotEmpty) 'name': name,
        if (surname.isNotEmpty) 'surname': surname,
        if (patronymic != null) 'patronymic': patronymic,
        if (city != null) 'city': city,
        if (age != null) 'age': age,
        if (sex != null) 'sex': sex,
        if (description.isNotEmpty) 'description': description,
        if (profession != null) 'profession': profession,
      };
}

class SocialLinkData {
  final String type;
  final String url;

  const SocialLinkData({required this.type, required this.url});
}