import 'package:chrysalis_mobile/features/profile/data/model/profile_user_model.dart';
import 'package:chrysalis_mobile/features/profile/domain/entity/profile_response_entity.dart';

class ProfileResponseModel extends ProfileResponseEntity {
  const ProfileResponseModel({
    required super.success,
    required super.user,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      success: json['success'] as bool? ?? false,
      user: ProfileUserModel.fromJson(json['data']['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': {
      'user': (user as ProfileUserModel).toJson(),
    },
  };
}