import 'package:chrysalis_mobile/features/homepage/domain/repository/home_repository.dart';

class MarkAllAsReadUseCase {
  MarkAllAsReadUseCase(this.repository);
  final HomeRepository repository;

  Future<void> call({required String type, required String chatId}) {
    return repository.markAllAsRead(type: type, chatId: chatId);
  }
}
