class ProfileUserEntity {
  const ProfileUserEntity({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.isActive,
    required this.isVerified,
    required this.role,
    required this.isNotification,
    required this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? avatar;
  final bool isActive;
  final bool isVerified;
  final String role;
  final bool isNotification;
  final String lastLogin;
  final String createdAt;
  final String updatedAt;

  String get displayName => '$firstName $lastName';
  
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    
    if (firstInitial.isNotEmpty && lastInitial.isNotEmpty) {
      return '$firstInitial$lastInitial';
    } else if (firstInitial.isNotEmpty) {
      return firstInitial.length >= 2 ? firstInitial.substring(0, 2) : firstInitial;
    } else if (username.isNotEmpty) {
      return username.length >= 2 ? username.substring(0, 2).toUpperCase() : username[0].toUpperCase();
    }
    
    return 'U';
  }
}