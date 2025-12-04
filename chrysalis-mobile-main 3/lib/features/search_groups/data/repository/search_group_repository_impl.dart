import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/features/search_groups/data/remote/search_group_remote_service.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';
import 'package:dio/dio.dart';

class SearchGroupRepositoryImpl implements SearchGroupRepository {
  SearchGroupRepositoryImpl(this.remoteService);
  final SearchGroupRemoteService remoteService;

  @override
  Future<List<SearchResultEntity>> getRecentSearches({int limit = 10}) {
    try {
      return remoteService.getRecentSearches(limit: limit);
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<List<SearchResultEntity>> search({
    required String query,
    int page = 1,
    int limit = 10,
  }) {
    try {
      return remoteService.search(
        query: query,
        page: page,
        limit: limit,
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<void> addToRecentSearch({required SearchResultEntity result}) {
    return remoteService.addToRecentSearch(result: result);
  }
}
