import 'package:chrysalis_mobile/features/profile/domain/entity/profile_user_entity.dart';

class ProfileResponseEntity {
  const ProfileResponseEntity({
    required this.success,
    required this.user,
  });

  final bool success;
  final ProfileUserEntity user;
}