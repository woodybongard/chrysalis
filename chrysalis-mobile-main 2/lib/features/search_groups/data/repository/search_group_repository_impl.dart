import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/search_groups/data/remote/search_group_remote_service.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';
import 'package:dio/dio.dart';

class SearchGroupRepositoryImpl implements SearchGroupRepository {
  SearchGroupRepositoryImpl(this.remoteService);
  final SearchGroupRemoteService remoteService;

  @override
  Future<List<GroupModel>> getRecentSearchGroups({int limit = 10}) {
    try {
      return remoteService.getRecentSearchGroups(limit: limit);
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<List<GroupModel>> searchGroupsByText({
    required String query,
    int page = 1,
    int limit = 10,
  }) {
    try {
      return remoteService.searchGroupsByText(
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
  Future<void> addGroupToRecentSearch({required String groupId}) {
    return remoteService.addGroupToRecentSearch(groupId: groupId);
  }
}
