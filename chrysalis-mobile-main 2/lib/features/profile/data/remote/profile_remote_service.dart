import 'dart:io';

import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/profile/data/model/profile_response_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

abstract class ProfileRemoteService {
  Future<ProfileResponseModel> getUserProfile();
  Future<Map<String, dynamic>> updatePassword(String userId, String currentPassword, String newPassword);
  Future<Map<String, dynamic>> toggleNotifications(bool isNotification);
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    File? image,
    XFile? imageFile,
  });
}

class ProfileRemoteServiceImpl implements ProfileRemoteService {
  ProfileRemoteServiceImpl(this.dioClient);
  final DioClient dioClient;

  @override
  Future<ProfileResponseModel> getUserProfile() async {
    try {
      final headers = await getHeaders();
      final response = await dioClient.get(
        ApiEndpoints.profile,
        options: Options(headers: headers),
      );
      return ProfileResponseModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> updatePassword(String userId, String currentPassword, String newPassword) async {
    try {
      final headers = await getHeaders();
      final response = await dioClient.put(
        ApiEndpoints.updatePassword,
        data: {
          'userId': userId,
          'currentPassword': currentPassword,
          'password': newPassword,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> toggleNotifications(bool isNotification) async {
    try {
      final headers = await getHeaders();
      final response = await dioClient.patch(
        ApiEndpoints.toggleNotification,
        data: {
          'isNotification': isNotification,
        },
        options: Options(headers: headers),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
    required String username,
    File? image,
    XFile? imageFile,
  }) async {
    try {
      final headers = await getHeaders();
      
      final formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'userName': username,
      });

      // Handle both File (mobile) and XFile (web) image types
      if (imageFile != null) {
        // Use XFile for both web and mobile for better compatibility
        final bytes = await imageFile.readAsBytes();
        formData.files.add(
          MapEntry(
            'file',
            MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name.isNotEmpty ? imageFile.name : 'profile_image.jpg',
            ),
          ),
        );
      } else if (image != null && !kIsWeb) {
        // Fallback to File for mobile/desktop when XFile is not provided
        formData.files.add(
          MapEntry(
            'file',
            await MultipartFile.fromFile(
              image.path,
              filename: 'profile_image.jpg',
            ),
          ),
        );
      }

      await dioClient.patch(
        ApiEndpoints.updateUserProfile,
        data: formData,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }
}