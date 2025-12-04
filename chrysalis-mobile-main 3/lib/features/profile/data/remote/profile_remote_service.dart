import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:flutter/foundation.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/profile/data/model/profile_response_model.dart';
import 'package:chrysalis_mobile/features/profile/data/remote/profile_web_service.dart';
import 'package:chrysalis_mobile/features/profile/data/remote/profile_mobile_service.dart';
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
  Future<void> updateUserProfileWeb({
    required String firstName,
    required String lastName,
    required String username,
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
  });
}

class ProfileRemoteServiceImpl implements ProfileRemoteService {
  ProfileRemoteServiceImpl(this.dioClient);
  final DioClient dioClient;
  
  late final ProfileWebService _webService = ProfileWebService(dioClient);
  late final ProfileMobileService _mobileService = ProfileMobileService(dioClient);

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
  }) async
  {
    debugPrint('🔄 ProfileRemoteService: Delegating to platform-specific service');
    debugPrint('💻 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      // No image provided, handle basic profile update
      try {
        MultipartFile? multipart;
        if (image != null || imageFile != null) {
          debugPrint("📸 Image detected → preparing multipart");

          if (kIsWeb && imageFile != null) {
            // Web: convert XFile → bytes
            final bytes = await imageFile.readAsBytes();
            multipart = MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            );
          } else if (!kIsWeb) {
            if (image != null) {
              // Mobile: convert File → Multipart
              multipart = await MultipartFile.fromFile(
                image.path,
                filename: image.path.split('/').last,
              );
            } else if (imageFile != null) {
              // Mobile: convert XFile → Multipart
              multipart = await MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.name,
              );
            }
          }
        }
        final headers = await getHeaders();
        final formData = FormData.fromMap({
          'firstName': firstName,
          'lastName': lastName,
          'userName': username,
          if (multipart != null) 'file': multipart,
        });

        debugPrint("📝 FormData Contents:");
        formData.fields.forEach((f) {
          debugPrint("   ➤ FIELD: ${f.key} = ${f.value}");
        });

        if (multipart != null) {
          debugPrint("   📸 FILE: ${multipart.filename} (${multipart.length} bytes)");
        } else {
          debugPrint("   📸 FILE: No file attached");
        }
        

        
        final response = await dioClient.patch(
          ApiEndpoints.updateUserProfile,
          data: formData,
          options: Options(headers: headers),
        );
        
        debugPrint('✅ Basic profile update successful - Status: ${response.statusCode}');
        return;
      } on DioException catch (e) {
        handleApiException(e);
        rethrow;
      }

  }

  @override
  Future<void> updateUserProfileWeb({
    required String firstName,
    required String lastName,
    required String username,
    required Uint8List imageBytes,
    required String fileName,
    required String mimeType,
  }) async {
    debugPrint('🌐 ProfileRemoteService: Direct web upload call');
    await _webService.updateUserProfileWeb(
      firstName: firstName,
      lastName: lastName,
      username: username,
      imageBytes: imageBytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}