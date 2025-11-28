import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/core/exception_handler/api_exception_handler.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/remote/chat_detail_remote_service.dart';
import 'package:chrysalis_mobile/features/homepage/data/local/home_local_datasource.dart';
import 'package:chrysalis_mobile/features/homepage/data/model/home_model.dart';
import 'package:chrysalis_mobile/features/homepage/data/remote/home_remote_service.dart';
import 'package:chrysalis_mobile/features/homepage/domain/entity/home_entity.dart';
import 'package:chrysalis_mobile/features/homepage/domain/repository/home_repository.dart';
import 'package:dio/dio.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this.remoteService, this.localDataSource);
  final HomeRemoteService remoteService;
  final HomeLocalDataSource localDataSource;

  @override
  Future<HomeEntity> getHomeData({int page = 1, int limit = 13}) async {
    try {
      final model = await remoteService.fetchChatList(page: page, limit: limit);
      await localDataSource.cacheChatList(
        groups: model.data.map((e) => e as GroupModel).toList(),
        page: page,
        limit: limit,
      );
      return _mapModelToEntity(model);
    } on DioException catch (e) {
      final cached = await localDataSource.getCachedChatList(
        page: page,
        limit: limit,
      );
      if (cached.isNotEmpty) {
        return _mapModelToEntity(HomeModel(
          data: cached,
          pagination: PaginationModel(
            page: page,
            limit: limit,
            total: cached.length,
            totalPages: 1,
          ),
        ));
      }
      // return empty instead of error to keep UI from showing error state
      return  HomeEntity(
        data: [],
        pagination: PaginationEntity(page: 1, limit: 13, total: 0, totalPages: 1),
      );
    }
  }

  HomeEntity _mapModelToEntity(HomeModel model) {
    return HomeEntity(
      data: model.data
          .map(
            (g) => GroupEntity(
              type: g.type,
              groupId: g.groupId,
              name: g.name,
              avatar: g.avatar,
              isGroup: g.isGroup,
              lastMessage: g.lastMessage != null
                  ? LastMessageEntity(
                      id: g.lastMessage!.id,
                      type: g.lastMessage!.type,
                      content: g.lastMessage!.content,
                      createdAt: g.lastMessage!.createdAt,
                      isSenderYou: g.lastMessage!.isSenderYou,
                      status: g.lastMessage!.status,
                      sender: SenderEntity(
                        id: g.lastMessage!.sender.id,
                        name: g.lastMessage!.sender.name,
                      ),

                      iv: g.lastMessage!.iv,
                      encryptedGroupKey: g.lastMessage!.encryptedGroupKey,
                      decryptedGroupKey: g.lastMessage!.decryptedGroupKey,
                    )
                  : null,
              unreadCount: g.unreadCount,
              groupKey: g.groupKey,
              version: g.version,
            ),
          )
          .toList(),
      pagination: PaginationEntity(
        page: model.pagination.page,
        limit: model.pagination.limit,
        total: model.pagination.total,
        totalPages: model.pagination.totalPages,
      ),
    );
  }

  @override
  Future<void> markAllAsRead({
    required String type,
    required String chatId,
  }) async {
    try {
      return await sl<ChatDetailRemoteService>().markAllAsRead(
        type: type,
        chatId: chatId,
      );
    } on DioException catch (e) {
      handleApiException(e);
      rethrow;
    }
  }
}
