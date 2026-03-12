/// Модель пользователя, возвращаемая сервером.
class AuthUser {
  final String id;
  final String email;
  final String? name;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        name: json['username'] as String?,
      );
}