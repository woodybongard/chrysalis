import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/auth_error_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/login_request_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/login_response_model.dart';
import 'package:chrysalis_mobile/features/authentication/data/model/logout_model.dart';
import 'package:dio/dio.dart';

abstract class AuthRemoteService {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<LogoutResponseModel> logout(
    LogoutRequestModel request,
    String accessToken,
  );

  Future<void> registerKey({
    required String publicKeyPem,
    required String privateKeyEnc,
    required String deviceId,
  });
}

class AuthRemoteServiceImpl implements AuthRemoteService {
  AuthRemoteServiceImpl(this.dioClient);
  @override
  Future<void> registerKey({
    required String publicKeyPem,
    required String privateKeyEnc,
    required String deviceId,
  }) async {
    try {
      final headers = await getHeaders();
      headers['x-device-id'] = deviceId;
      await dioClient.post(
        ApiEndpoints.registerKey,
        data: {'publicKeyPem': publicKeyPem, 'privateKeyEnc': privateKeyEnc},
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  final DioClient dioClient;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final headers = await getHeaders(
      deviceId: request.deviceId,
      includeDeviceId: true,
    );
    try {
      final response = await dioClient.post(
        ApiEndpoints.login,
        data: request.toJson(),
        options: Options(headers: headers),
      );
      final responseData = response.data as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return LoginResponseModel.fromJson(
          responseData['data'] as Map<String, dynamic>,
        );
      } else {
        throw AuthErrorModel.fromJson(responseData);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw AuthErrorModel.fromJson(e.response?.data as Map<String, dynamic>);
      } else {
        throw AuthErrorModel(message: e.message ?? 'Unknown error');
      }
    } catch (e) {
      throw AuthErrorModel(message: e.toString());
    }
  }

  @override
  Future<LogoutResponseModel> logout(
    LogoutRequestModel request,
    String accessToken,
  ) async {
    try {
      final headers = await getHeaders();
      final response = await dioClient.post(
        ApiEndpoints.logout,
        data: request.toJson(),
        options: Options(headers: headers),
      );
      return LogoutResponseModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }
}
