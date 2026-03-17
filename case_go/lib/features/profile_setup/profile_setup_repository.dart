import 'dart:developer' as dev;
import 'package:case_go/core/api/profile/profile.dart';
import 'package:case_go/features/profile_setup/profile_setup_extra.dart';

/// Репозиторий, изолирует логику отправки профиля от UI.
class ProfileSetupRepository {
  final ProfileApi _api;

  ProfileSetupRepository(this._api);

  Future<void> submit({
    required ProfileSetupMode mode,
    required ProfileSetupData data,
  }) async {
    dev.log('📡 ProfileSetupRepository.submit: mode=$mode', name: 'ProfileSetup');
    switch (mode) {
      case ProfileSetupMode.create:
        dev.log('📡 calling createProfile...', name: 'ProfileSetup');
        final result = await _api.createProfile(data.toCreateRequest());
        dev.log('📡 createProfile returned: $result', name: 'ProfileSetup');
      case ProfileSetupMode.edit:
        dev.log('📡 calling updateProfile...', name: 'ProfileSetup');
        final result = await _api.updateProfile(data.toPartialUpdateRequest());
        dev.log('📡 updateProfile returned: $result', name: 'ProfileSetup');
    }
  }
}

/// Данные формы профиля.
class ProfileSetupData {
  final String username;
  final String name;
  final String surname;
  final String? patronymic;
  final String? city;
  final int? age;
  final int? sex;
  final String description;
  final String? profession;
  final List<String> purposes;
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

  Map<String, dynamic> toCreateRequest() => {
        'info': {
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