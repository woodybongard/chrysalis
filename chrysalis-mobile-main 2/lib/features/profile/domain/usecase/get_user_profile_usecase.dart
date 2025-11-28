import 'package:chrysalis_mobile/features/profile/domain/entity/profile_response_entity.dart';
import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';

class GetUserProfileUseCase {
  const GetUserProfileUseCase(this.repository);
  
  final ProfileRepository repository;

  Future<ProfileResponseEntity> call() async {
    return repository.getUserProfile();
  }
}