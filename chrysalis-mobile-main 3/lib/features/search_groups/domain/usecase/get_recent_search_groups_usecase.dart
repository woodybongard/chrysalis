import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class GetRecentSearchesUseCase {
  GetRecentSearchesUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<List<SearchResultEntity>> call({int limit = 10}) {
    return repository.getRecentSearches(limit: limit);
  }
}
