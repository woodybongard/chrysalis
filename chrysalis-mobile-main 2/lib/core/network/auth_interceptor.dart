import 'dart:developer';

import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/interceptors.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/utils/toast_utils.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/tokens_model.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Prevent infinite loop: if the failing request is refreshToken itself, just logout
    if (err.response?.statusCode == 401 &&
        err.requestOptions.path != ApiEndpoints.refreshToken &&
        err.requestOptions.path != ApiEndpoints.login) {
      final refreshToken = await LocalStorage().read(key: AppKeys.refreshToken);

      if (refreshToken != null) {
        try {
          await _refreshToken(refreshToken);
          final accessToken = await LocalStorage().read(
            key: AppKeys.accessToken,
          );

          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $accessToken';

          final retryResponse = await sl<DioClient>().dio.fetch<dynamic>(opts);
          return handler.resolve(retryResponse);
        } catch (e) {
          await _logoutUser();
          return handler.next(err);
        }
      } else {
        await _logoutUser();
        return handler.next(err);
      }
    }

    loggerOnError(err);
    return handler.next(err);
  }

  Future<void> _refreshToken(String refreshToken) async {
    final refreshResponse = await sl<DioClient>().post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    if (refreshResponse.statusCode == 401 ||
        refreshResponse.statusCode == 500) {
      throw Exception('Refresh failed');
    }
    final storage = sl<LocalStorage>();
    final responseData = refreshResponse.data;
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    final dataMap = responseData['data'];
    if (dataMap is! Map<String, dynamic>) {
      throw Exception('Invalid data format');
    }
    final tokensMap = dataMap['tokens'];
    if (tokensMap is! Map<String, dynamic>) {
      throw Exception('Invalid tokens format');
    }
    final tokens = TokensModel.fromJson(tokensMap);
    await storage.write(key: AppKeys.accessToken, value: tokens.accessToken);
    await storage.write(key: AppKeys.refreshToken, value: tokens.refreshToken);
  }

  Future<void> _logoutUser() async {
    try {
      await LocalStorage().clear();
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ToastUtils.showError(message: 'Session expired. Please log in again.', context: context);
        context.go(AppRoutes.signIn);
      }
    } catch (_) {
      await LocalStorage().clear();
    }
    log('User logged out due to invalid/expired refresh token');
  }
}
