/// Модель пользователя, возвращаемая сервером.
class AuthUser {
  final String id;
  final String email;
  final String? name;
  final int role;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    this.role = 1,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'].toString(),
        email: json['email'] as String,
        name: json['username'] as String?,
        role: (json['role'] as num?)?.toInt() ?? 1,
      );
}