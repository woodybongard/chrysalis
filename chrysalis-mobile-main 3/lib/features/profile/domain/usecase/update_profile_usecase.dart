import 'dart:io';
import 'dart:typed_data';

import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';
import 'package:image_picker/image_picker.dart';

class UpdateProfileUsecase {
  UpdateProfileUsecase(this.repository);
  final ProfileRepository repository;

  Future<void> call({
    required String firstName,
    required String lastName,
    required String username,
    File? image,
    XFile? imageFile,
  }) async {
    await repository.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      image: image,
      imageFile: imageFile,
    );
  }

  Future<void> callWeb({
    required String firstName,
    required String lastName,
    required String username,
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
  }) async {
    await repository.updateUserProfileWeb(
      firstName: firstName,
      lastName: lastName,
      username: username,
      imageBytes: imageBytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}