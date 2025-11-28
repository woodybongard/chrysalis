import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';

abstract class HomeRepository {
  Future<HomeEntity> getHomeData({int page = 1, int limit = 13});
  Future<void> markAllAsRead({required String type, required String chatId});
}
