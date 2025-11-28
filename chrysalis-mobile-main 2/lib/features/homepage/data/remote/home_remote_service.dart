import 'dart:developer';

import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:dio/dio.dart';

abstract class HomeRemoteService {
  Future<HomeModel> fetchChatList({int page, int limit});
}

class HomeRemoteServiceImpl implements HomeRemoteService {
  HomeRemoteServiceImpl(this.dioClient);
  final DioClient dioClient;

  @override
  Future<HomeModel> fetchChatList({int page = 1, int limit = 13}) async {
    try {
      final headers = await getHeaders();
      final response = await dioClient.get(
        ApiEndpoints.chatList,
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: headers),
      );
      log('Homepage response: ${response.data}');
      return HomeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }
}
