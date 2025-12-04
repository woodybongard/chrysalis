import 'package:chrysalis_mobile/features/chat_detail/domain/entity/message_entity.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/repository/chat_detail_repository.dart';

class GetMessagesUseCase {
  GetMessagesUseCase(this.repository);
  final ChatDetailRepository repository;

  Future<PaginatedMessagesEntity> call({
    required String type,
    required String id,
    int page = 1,
    int limit = 20,
  }) async {
    return repository.getMessages(type: type, id: id, page: page, limit: limit);
  }
}
