import 'package:chrysalis_mobile/features/authentication/domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.role,
    required super.firstName,
    required super.lastName,
    required super.isActive,
    required super.isVerified,
    required super.lastLogin,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      lastLogin: json['lastLogin'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'role': role,
    'firstName': firstName,
    'lastName': lastName,
    'isActive': isActive,
    'isVerified': isVerified,
    'lastLogin': lastLogin,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
