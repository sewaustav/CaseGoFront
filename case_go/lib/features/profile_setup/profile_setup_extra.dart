/// Режим экрана заполнения профиля.
///
/// Передаётся через GoRouter extra при навигации на /profile/setup.
/// Это позволяет переиспользовать один экран и для первичного создания
/// профиля (после регистрации), и для редактирования существующего.
enum ProfileSetupMode {
  /// Первичное создание профиля — отправляет POST /profile
  create,

  /// Редактирование существующего профиля — отправляет PATCH /profile
  edit,
}

class ProfileSetupExtra {
  final ProfileSetupMode mode;

  const ProfileSetupExtra({required this.mode});
}