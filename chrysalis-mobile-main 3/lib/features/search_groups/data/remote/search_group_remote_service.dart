import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/search_groups/data/model/search_result_model.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/entity/search_result_entity.dart';
import 'package:dio/dio.dart';

class SearchGroupRemoteService {
  SearchGroupRemoteService(this.dio);
  final DioClient dio;

  /// GET /api/v1/search - Search across groups, conversations, and users
  Future<List<SearchResultModel>> search({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await dio.get(
        ApiEndpoints.searchGroupsByText,
        queryParameters: {'query': query, 'page': page, 'limit': limit},
        options: Options(headers: headers),
      );
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List;
      return data
          .map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  /// GET /api/v1/search/recent-search - Get recent searches
  Future<List<SearchResultModel>> getRecentSearches({int limit = 10}) async {
    try {
      final headers = await getHeaders();
      final response = await dio.get(
        ApiEndpoints.getRecentGroup,
        queryParameters: {'limit': limit},
        options: Options(headers: headers),
      );
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as List;
      return data
          .map((e) => SearchResultModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  /// POST /api/v1/search/recent-search - Add to recent searches
  Future<void> addToRecentSearch({
    required SearchResultEntity result,
  }) async {
    try {
      final headers = await getHeaders();
      final Map<String, dynamic> body;

      switch (result.type) {
        case 'group':
          body = {'groupId': result.id};
        case 'conversation':
          body = {'conversationId': result.id};
        case 'user':
          body = {'searchedUserId': result.id};
        default:
          return;
      }

      await dio.post(
        ApiEndpoints.addGroupToRecentSearch,
        data: body,
        options: Options(headers: headers),
      );
    } catch (_) {
      // No error or loading UI needed
    }
  }
}
