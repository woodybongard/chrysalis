import 'dart:io';
import 'dart:typed_data';

import 'package:chrysalis_mobile/features/profile/domain/entity/profile_response_entity.dart';
import 'package:image_picker/image_picker.dart';

abstract class ProfileRepository {
  Future<ProfileResponseEntity> getUserProfile();
  Future<String> updatePassword(String userId, String currentPassword, String newPassword);
  Future<String> toggleNotifications(bool isNotification);
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    File? image,
    XFile? imageFile,
  });
  Future<void> updateUserProfileWeb({
    required String firstName,
    required String lastName,
    required String username,
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
  });
}