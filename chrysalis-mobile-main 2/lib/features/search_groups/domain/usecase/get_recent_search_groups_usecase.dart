import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class GetRecentSearchGroupsUseCase {
  GetRecentSearchGroupsUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<List<GroupModel>> call({int limit = 10}) {
    return repository.getRecentSearchGroups(limit: limit);
  }
}
