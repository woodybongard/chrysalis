import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';

class SearchUseCase {
  SearchUseCase(this.repository);
  final SearchGroupRepository repository;

  Future<List<SearchResultEntity>> call({
    required String query,
    int page = 1,
    int limit = 10,
  }) {
    return repository.search(query: query, page: page, limit: limit);
  }
}
