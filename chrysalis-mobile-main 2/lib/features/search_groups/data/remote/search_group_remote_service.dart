import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:dio/dio.dart';

class SearchGroupRemoteService {
  SearchGroupRemoteService(this.dio);
  final DioClient dio;

  Future<List<GroupModel>> getRecentSearchGroups({int limit = 10}) async {
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
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  Future<List<GroupModel>> searchGroupsByText({
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
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  Future<void> addGroupToRecentSearch({required String groupId}) async {
    try {
      final headers = await getHeaders();
      await dio.post(
        ApiEndpoints.addGroupToRecentSearch,
        data: {'groupId': groupId},
        options: Options(headers: headers),
      );
    } catch (_) {
      // No error or loading UI needed
    }
  }
}
