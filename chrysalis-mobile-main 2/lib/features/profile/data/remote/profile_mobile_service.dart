import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

/// Mobile-specific profile service using 2025 Flutter best practices
/// Optimized for iOS and Android platforms
class ProfileMobileService {
  ProfileMobileService(this.dioClient);
  final DioClient dioClient;

  Future<void> updateUserProfileMobile({
    required String firstName,
    required String lastName,
    required String username,
    required XFile imageFile,
  }) async {
    try {
      debugPrint('📱 ProfileMobileService 2025: Starting mobile profile update');
      debugPrint('📂 XFile path: ${imageFile.path}');
      debugPrint('📂 XFile name: ${imageFile.name}');
      debugPrint('📂 XFile mime type: ${imageFile.mimeType}');
      
      final headers = await getHeaders();
      
      // 2025 Mobile best practice: Use XFile.readAsBytes() for consistency
      // This ensures the same data handling approach across platforms
      final imageBytes = await imageFile.readAsBytes();
      debugPrint('✅ Mobile: Read ${imageBytes.length} bytes from XFile');
      
      // Validate file is not empty
      if (imageBytes.isEmpty) {
        throw Exception('Image file is empty or could not be read');
      }
      
      // Use consistent filename and content type approach
      final sanitizedFilename = _sanitizeFilename(imageFile.name);
      final contentType = _determineContentType(imageFile.mimeType, sanitizedFilename);
      
      debugPrint('📝 Using filename: $sanitizedFilename');
      debugPrint('📝 Using content type: ${contentType.mimeType}/${contentType.subtype}');
      
      // Create FormData using bytes approach for consistency with web
      final formData = FormData.fromMap({
        'firstName': firstName,
        'lastName': lastName,
        'userName': username,
        'file': MultipartFile.fromBytes(
          imageBytes,
          filename: sanitizedFilename,
          contentType: contentType,
        ),
      });
      
      debugPrint('🚀 Mobile: Uploading ${formData.files.length} files using bytes');
      debugPrint('📊 Total form data fields: ${formData.fields.length}');
      
      // Log all FormData fields
      debugPrint('📋 Mobile FormData Fields:');
      for (final field in formData.fields) {
        debugPrint('   ${field.key}: ${field.value}');
      }
      
      // Log all FormData files
      debugPrint('📁 Mobile FormData Files:');
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
          contentType: 'multipart/form-data',
        ),
      );
      
      debugPrint('✅ Mobile: Profile update successful - Status: ${response.statusCode}');
      debugPrint('📡 Response headers: ${response.headers}');
    } on DioException catch (e) {
      debugPrint('❌ Mobile DioException: ${e.message}');
      debugPrint('📡 Response data: ${e.response?.data}');
      debugPrint('📡 Response status: ${e.response?.statusCode}');
      debugPrint('📡 Request data type: ${e.requestOptions.data.runtimeType}');
      debugPrint('🔍 Error type: ${e.type}');
      handleApiException(e);
      rethrow;
    } catch (e) {
      debugPrint('❌ Mobile general error: $e');
      debugPrint('🔍 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Sanitize filename for mobile upload - 2025 best practices
  String _sanitizeFilename(String? filename) {
    if (filename == null || filename.isEmpty) {
      return 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    
    String sanitized = filename
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    
    if (!sanitized.contains('.') || !_isValidImageExtension(sanitized)) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      sanitized = 'profile_${timestamp}.jpg';
    }
    
    return sanitized;
  }

  /// Determine content type based on 2025 best practices
  DioMediaType _determineContentType(String? mimeType, String filename) {
    if (mimeType != null && mimeType.isNotEmpty && mimeType.contains('/')) {
      final parts = mimeType.split('/');
      if (parts.length == 2 && parts[0] == 'image') {
        return DioMediaType(parts[0], parts[1]);
      }
    }
    
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
      case 'heic':
        return DioMediaType('image', 'heic');
      default:
        return DioMediaType('image', 'jpeg');
    }
  }
  
  /// Check if filename has valid image extension
  bool _isValidImageExtension(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension);
  }
}