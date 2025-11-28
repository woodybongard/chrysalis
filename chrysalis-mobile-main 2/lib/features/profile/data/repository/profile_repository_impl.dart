import 'dart:io';

import 'package:chrysalis_mobile/features/profile/data/remote/profile_remote_service.dart';
import 'package:chrysalis_mobile/features/profile/domain/entity/profile_response_entity.dart';
import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this.remoteService);
  final ProfileRemoteService remoteService;

  @override
  Future<ProfileResponseEntity> getUserProfile() async {
    return remoteService.getUserProfile();
  }

  @override
  Future<String> updatePassword(String userId, String currentPassword, String newPassword) async {
    final response = await remoteService.updatePassword(userId, currentPassword, newPassword);
    return response['message'] as String;
  }

  @override
  Future<String> toggleNotifications(bool isNotification) async {
    final response = await remoteService.toggleNotifications(isNotification);
    return response['message'] as String;
  }

  @override
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    File? image,
    XFile? imageFile,
  }) async {
    await remoteService.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      image: image,
      imageFile: imageFile,
    );
  }
}