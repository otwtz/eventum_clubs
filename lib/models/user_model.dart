/// Модель пользователя приложения.
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String city;
  final String username;
  final String? photoPath;

  const UserModel({
    this.id = '',
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.username,
    this.photoPath,
  });

  String get fullName => '$firstName $lastName'.trim();
}
