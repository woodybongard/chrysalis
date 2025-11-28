import 'dart:io';

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
}