/// Модель пользователя, возвращаемая сервером.
class AuthUser {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
      );
}