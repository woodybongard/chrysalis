import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/local/chat_detail_local_datasource.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/model/message_model.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/remote/chat_detail_remote_service.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/send_message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/repository/chat_detail_repository.dart';
import 'package:dio/dio.dart';

class ChatDetailRepositoryImpl implements ChatDetailRepository {
  ChatDetailRepositoryImpl(this.remoteService, this.localDataSource);
  final ChatDetailRemoteService remoteService;
  final ChatDetailLocalDataSource localDataSource;

  @override
  Future<PaginatedMessagesEntity> getMessages({
    required String type,
    required String id,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final paginatedModel = await remoteService.fetchPaginatedMessages(
        type: type,
        id: id,
        page: page,
        limit: limit,
      );
      // cache remote page results
      await localDataSource.cacheMessages(
        type: type,
        id: id,
        messages: paginatedModel.messages,
        page: page,
      );
      return PaginatedMessagesEntity(
        messages: paginatedModel.messages
            .map(
              (m) => MessageEntity(
                id: m.id,
                conversationId: m.conversationId,
                groupId: m.groupId,
                senderId: m.senderId,
                encryptedText: m.encryptedText,
                type: m.type,
                status: m.status,
                fileUrl: m.fileUrl,
                createdAt: m.createdAt,
                avatar: m.avatar,
                senderName: m.senderName,
                isSenderYou: m.isSenderYou,
                iv: m.iv,
                encryptedGroupKey: m.encryptedGroupKey,
                fileName: m.fileName,
                fileType: m.fileType,
                fileSize: m.fileSize,
                filePages: m.filePages,
                reactions: m.reactions,
              ),
            )
            .toList(),
        pagination: MessagePaginationEntity(
          page: paginatedModel.pagination.page,
          limit: paginatedModel.pagination.limit,
          totalPages: paginatedModel.pagination.totalPages,
          total: paginatedModel.pagination.total,
        ),
      );
    } on DioException catch (e) {
      // try local fallback
      final cached = await localDataSource.getCachedMessages(
        type: type,
        id: id,
        page: page,
      );
      if (cached.isNotEmpty) {
        return PaginatedMessagesEntity(
          messages: cached
              .map(
                (m) => MessageEntity(
                  id: m.id,
                  conversationId: m.conversationId,
                  groupId: m.groupId,
                  senderId: m.senderId,
                  encryptedText: m.encryptedText,
                  type: m.type,
                  status: m.status,
                  fileUrl: m.fileUrl,
                  createdAt: m.createdAt,
                  avatar: m.avatar,
                  senderName: m.senderName,
                  isSenderYou: m.isSenderYou,
                  iv: m.iv,
                  encryptedGroupKey: m.encryptedGroupKey,
                  fileName: m.fileName,
                  fileType: m.fileType,
                  fileSize: m.fileSize,
                  filePages: m.filePages,
                  reactions: m.reactions,
                ),
              )
              .toList(),
          pagination: MessagePaginationEntity(
            page: page,
            limit: limit,
            totalPages: page, // unknown; use page as sentinel
            total: cached.length,
          ),
        );
      }
      // No cache available, return empty result instead of throwing
      return const PaginatedMessagesEntity(
        messages: [],
        pagination: MessagePaginationEntity(
          page: 1,
          limit: 20,
          totalPages: 1,
          total: 0,
        ),
      );

    }
  }

  @override
  Future<MessageEntity> sendMessage({
    required GroupMessageEntity entity,
  }) async {
    try {
      final model = await remoteService.sendTextMessage(entity: entity);
      // cache the sent message locally under page 1
      await localDataSource.upsertMessage(
        type: entity.isGroup ? 'group' : 'conversation',
        id: entity.groupId,
        message: MessageModel(
          id: model.id,
          conversationId: model.conversationId,
          groupId: model.groupId,
          senderId: model.senderId,
          encryptedText: model.encryptedText,
          type: model.type,
          status: model.status,
          fileUrl: model.fileUrl,
          createdAt: model.createdAt,
          avatar: model.avatar,
          senderName: model.senderName,
          isSenderYou: model.isSenderYou,
          iv: model.iv,
          encryptedGroupKey: model.encryptedText,
          decryptGroupKey: null,
        ),
      );
      return MessageEntity(
        id: model.id,
        conversationId: model.conversationId,
        groupId: model.groupId,
        senderId: model.senderId,
        encryptedText: model.encryptedText,
        type: model.type,
        status: model.status,
        fileUrl: model.fileUrl,
        createdAt: model.createdAt,
        avatar: model.avatar,
        senderName: model.senderName,
        isSenderYou: model.isSenderYou,
        iv: model.iv,
        encryptedGroupKey: model.encryptedText,
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }
}
