import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/send_message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/repository/chat_detail_repository.dart';

class SendMessageUseCase {
  SendMessageUseCase(this.repository);
  final ChatDetailRepository repository;

  Future<MessageEntity> call({required GroupMessageEntity entity}) async {
    return repository.sendMessage(entity: entity);
  }
}
