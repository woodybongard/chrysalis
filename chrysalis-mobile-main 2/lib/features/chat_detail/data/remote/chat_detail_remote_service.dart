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
        final formData = FormData.fromMap({
          ...body,
          'type': 'FILE',
          'fileName': entity.fileName,
          'fileType': entity.fileType,
          'fileSize': entity.fileSize,
          'filePages': 1,
          'file': await MultipartFile.fromFile(
            entity.filePath!,
            filename: entity.fileName,
          ),
        });

        response = await dioClient.post(
          ApiEndpoints.sendMessage,
          data: formData,
          options: Options(
            headers: {...headers, 'Content-Type': 'multipart/form-data'},
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
}
