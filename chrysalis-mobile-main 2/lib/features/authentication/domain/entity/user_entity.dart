class UserEntity {
  const UserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.isVerified,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String email;
  final String username;
  final String role;
  final String firstName;
  final String lastName;
  final bool isActive;
  final bool isVerified;
  final String lastLogin;
  final String createdAt;
  final String updatedAt;
}
