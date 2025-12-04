import 'package:chrysalis_mobile/core/endpoints/api_endpoints.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/header.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/model/message_model.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/send_message_entity.dart';
import 'package:dio/dio.dart';

abstract class ChatDetailRemoteService {
  Future<PaginatedMessagesModel> fetchPaginatedMessages({
    required String type,
    required String id,
    int page = 1,
    int limit = 20,
  });

  Future<MessageModel> sendTextMessage({required GroupMessageEntity entity});

  Future<void> markAllAsRead({
    required String type, // 'group' or 'conversation'
    required String chatId,
  });
}

class ChatDetailRemoteServiceImpl implements ChatDetailRemoteService {
  ChatDetailRemoteServiceImpl(this.dioClient);

  final DioClient dioClient;

  @override
  Future<PaginatedMessagesModel> fetchPaginatedMessages({
    required String type,
    required String id,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await getHeaders();
    final response = await dioClient.get(
      ApiEndpoints.messages,
      queryParameters: {'type': type, 'id': id, 'page': page, 'limit': limit},
      options: Options(headers: headers),
    );

    return PaginatedMessagesModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<MessageModel> sendTextMessage({
    required GroupMessageEntity entity,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {
        if (entity.isGroup)
          'groupId': entity.groupId
        else
          'recipientId': entity.groupId,
        'content': entity.content,
        'type': 'TEXT',
        'iv': entity.iv,
        'aesKeyEncB64Url': entity.encryptedGroupKey,
        'version': entity.version,
      };
      Response<dynamic> response;
      if (entity.type == 'FILE') {
        // Determine content type based on file extension
        final contentType = _determineContentType(entity.fileType);

        final formData = FormData.fromMap({
          ...body,
          'type': 'FILE',
          'fileName': entity.fileName,
          'fileType': entity.fileType,
          'fileSize': entity.fileSize,
          'filePages': 1,
          'file': MultipartFile.fromBytes(
            entity.fileBytes!,
            filename: entity.fileName,
            contentType: contentType,
          ),
        });

        response = await dioClient.post(
          ApiEndpoints.sendMessage,
          data: formData,
          options: Options(
            headers: {...headers, 'Content-Type': 'multipart/form-data'},
            // Extended timeout for large file uploads (30 minutes)
            sendTimeout: DioClient.fileUploadTimeout,
            receiveTimeout: DioClient.fileUploadTimeout,
          ),
        );
      } else {
        response = await dioClient.post(
          ApiEndpoints.sendMessage,
          data: body,
          options: Options(headers: headers),
        );
      }

      final dynamic raw = response.data;
      final dynamic nested = (raw is Map<String, dynamic>)
          ? (raw['data'] is Map<String, dynamic>
                ? (raw['data'] as Map<String, dynamic>)['message']
                : raw['message'])
          : null;
      final json = (nested is Map<String, dynamic>)
          ? nested
          : (raw as Map<String, dynamic>);
      return MessageModel.fromJson(json);
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead({
    required String type,
    required String chatId,
  }) async {
    try {
      final headers = await getHeaders();
      final body = {'type': type, 'chatId': chatId};
      await dioClient.post(
        ApiEndpoints.markAllAsRead,
        data: body,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }

  /// Determine content type based on file extension
  DioMediaType _determineContentType(String? fileExtension) {
    final extension = fileExtension?.toLowerCase();

    switch (extension) {
      // Documents
      case 'pdf':
        return DioMediaType('application', 'pdf');
      case 'doc':
        return DioMediaType('application', 'msword');
      case 'docx':
        return DioMediaType(
          'application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document',
        );
      case 'exe':
        return DioMediaType('application', 'vnd.microsoft.portable-executable');

      // Medical
      case 'dcm':
        return DioMediaType('application', 'dicom');

      // Images
      case 'jpg':
      case 'jpeg':
        return DioMediaType('image', 'jpeg');
      case 'png':
        return DioMediaType('image', 'png');
      case 'gif':
        return DioMediaType('image', 'gif');
      case 'heic':
        return DioMediaType('image', 'heic');

      // Default for unknown file types
      default:
        return DioMediaType('application', 'octet-stream');
    }
  }
}
