import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';
import 'package:chrysalis_mobile/features/homepage/domain/repository/home_repository.dart';

class GetHomeDataUseCase {
  GetHomeDataUseCase(this.repository);
  final HomeRepository repository;

  Future<HomeEntity> call({int page = 1, int limit = 13}) async {
    return repository.getHomeData(page: page, limit: limit);
  }
}
