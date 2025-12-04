import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';

abstract class SearchGroupRepository {
  Future<List<SearchResultEntity>> getRecentSearches({int limit});
  Future<List<SearchResultEntity>> search({
    required String query,
    int page,
    int limit,
  });
  Future<void> addToRecentSearch({required SearchResultEntity result});
}
