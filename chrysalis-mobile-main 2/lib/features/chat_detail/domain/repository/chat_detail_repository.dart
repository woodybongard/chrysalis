import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/send_message_entity.dart';

abstract class ChatDetailRepository {
  Future<PaginatedMessagesEntity> getMessages({
    required String type,
    required String id,
    int page = 1,
    int limit = 20,
  });

  Future<MessageEntity> sendMessage({required GroupMessageEntity entity});
}
