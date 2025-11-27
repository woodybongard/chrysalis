import 'package:chrysalis_mobile/features/profile/domain/entity/profile_user_entity.dart';

class ProfileUserModel extends ProfileUserEntity {
  const ProfileUserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.firstName,
    required super.lastName,
    super.avatar,
    required super.isActive,
    required super.isVerified,
    required super.role,
    required super.isNotification,
    required super.lastLogin,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      avatar: json['avatar'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      role: json['role'] as String? ?? '',
      isNotification: json['isNotification'] as bool? ?? false,
      lastLogin: json['lastLogin'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'avatar': avatar,
    'isActive': isActive,
    'isVerified': isVerified,
    'role': role,
    'isNotification': isNotification,
    'lastLogin': lastLogin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}