import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';

/// Web-specific profile service using 2025 Flutter best practices
/// Uses file_picker and direct bytes handling for web compatibility
class ProfileWebService {
  ProfileWebService(this.dioClient);
  final DioClient dioClient;

  Future<void> updateUserProfileWeb({
    required String firstName,
    required String lastName,
    required String username,
    required Uint8List imageBytes,
    required String fileName,
    required String? mimeType,
  }) async {
    try {
      debugPrint('🌐 ProfileWebService 2025: Starting web profile update');
      debugPrint('📂 File name: $fileName');
      debugPrint('📂 MIME type: $mimeType');
      debugPrint('📂 File size: ${imageBytes.length} bytes');
      
      final headers = await getHeaders();
      
      // Validate file is not empty
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty or could not be read');
      }
      
      // 2025 best practice: Use explicit filename and content type for web upload
      final sanitizedFilename = _sanitizeFilename(fileName);
      final contentType = _determineContentType(mimeType, sanitizedFilename);
      
      debugPrint('📝 Using filename: $sanitizedFilename');
      debugPrint('📝 Using content type: ${contentType.mimeType}/${contentType.subtype}');
      
      // Create FormData using 2025 Flutter web best practices
      final formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'userName': username,
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: sanitizedFilename, // Required for web compatibility
          contentType: contentType, // Explicit content type prevents server validation issues
        ),
      });
      
      debugPrint('🚀 Web: Uploading ${formData.files.length} files using FormData.fromMap');
      debugPrint('📊 Total form data fields: ${formData.fields.length}');
      
      // Log all FormData fields
      debugPrint('📋 Web FormData Fields:');
      for (final field in formData.fields) {
        debugPrint('   ${field.key}: ${field.value}');
      }
      
      // Log all FormData files
      debugPrint('📁 Web FormData Files:');
      for (final file in formData.files) {
        debugPrint('   ${file.key}: ${file.value.filename} (${file.value.length} bytes, ${file.value.contentType})');
      }
      
      final response = await dioClient.patch(
        ApiEndpoints.updateUserProfile,
        data: formData,
        options: Options(
          headers: headers,
          sendTimeout: DioClient.fileUploadTimeout, // 30 minutes for large files
          receiveTimeout: DioClient.fileUploadTimeout,
          contentType: 'multipart/form-data', // Explicit content type
        ),
      );
      
      debugPrint('✅ Web: Profile update successful - Status: ${response.statusCode}');
      debugPrint('📡 Response headers: ${response.headers}');
    } on DioException catch (e) {
      debugPrint('❌ Web DioException: ${e.message}');
      debugPrint('📡 Response data: ${e.response?.data}');
      debugPrint('📡 Response status: ${e.response?.statusCode}');
      debugPrint('📡 Request data type: ${e.requestOptions.data.runtimeType}');
      debugPrint('🔍 Error type: ${e.type}');
      handleApiException(e);
      rethrow;
    } catch (e) {
      debugPrint('❌ Web general error: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Sanitize filename for web upload - 2025 best practices
  String _sanitizeFilename(String? filename) {
    if (filename == null || filename.isEmpty) {
      // Use timestamp for unique filename
      return 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    
    // Remove any problematic characters for web
    String sanitized = filename
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase(); // Lowercase for consistency
    
    // Ensure it has a valid image extension
    if (!sanitized.contains('.') || !_isValidImageExtension(sanitized)) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      sanitized = 'profile_${timestamp}.jpg';
    }
    
    return sanitized;
  }

  /// Determine content type based on 2025 best practices
  DioMediaType _determineContentType(String? mimeType, String filename) {
    // Priority 1: Use XFile mimeType if available and valid
    if (mimeType != null && mimeType.isNotEmpty && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      if (parts.length == 2 && parts[0] == 'image') {
        return DioMediaType(parts[0], parts[1]);
      }
    }
    
    // Priority 2: Determine from file extension
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return DioMediaType('image', 'jpeg');
      case 'png':
        return DioMediaType('image', 'png');
      case 'gif':
        return DioMediaType('image', 'gif');
      case 'webp':
        return DioMediaType('image', 'webp');
      default:
        // Default to JPEG for unknown types
        return DioMediaType('image', 'jpeg');
    }
  }
  
  /// Check if filename has valid image extension
  bool _isValidImageExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }
}