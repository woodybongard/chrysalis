import 'package:chrysalis_mobile/features/authentication/domain/entity/auth_error_entity.dart';

class AuthErrorModel extends AuthErrorEntity {
  const AuthErrorModel({required super.message, super.details});

  factory AuthErrorModel.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    return AuthErrorModel(
      message: error is Map<String, dynamic>
          ? (error['message'] as String? ?? '')
          : '',
      details: error is Map<String, dynamic>
          ? (error['details'] as List<dynamic>?)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {'message': message, 'details': details};
}
