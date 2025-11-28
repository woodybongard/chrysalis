import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/network/dio_client.dart';
import 'package:chrysalis_mobile/core/network/socket_service.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/features/authentication/data/remote/auth_remote_service.dart';
import 'package:chrysalis_mobile/features/authentication/data/repository/auth_repository_impl.dart';
import 'package:chrysalis_mobile/features/authentication/domain/repository/auth_repository.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/login_usecase.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/logout_usecase.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/register_key_usecase.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/local/chat_detail_local_datasource.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/remote/chat_detail_remote_service.dart';
import 'package:chrysalis_mobile/features/chat_detail/data/repository/chat_detail_repository_impl.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/repository/chat_detail_repository.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/get_messages_usecase.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/send_message_usecase.dart';
import 'package:chrysalis_mobile/features/homepage/data/local/home_local_datasource.dart';
import 'package:chrysalis_mobile/features/homepage/data/remote/home_remote_service.dart';
import 'package:chrysalis_mobile/features/homepage/data/repository/home_repository_impl.dart';
import 'package:chrysalis_mobile/features/homepage/domain/repository/home_repository.dart';
import 'package:chrysalis_mobile/features/homepage/domain/usecase/get_home_data_usecase.dart';
import 'package:chrysalis_mobile/features/homepage/domain/usecase/read_all_mark_usecase.dart';
import 'package:chrysalis_mobile/features/profile/data/remote/profile_remote_service.dart';
import 'package:chrysalis_mobile/features/profile/data/repository/profile_repository_impl.dart';
import 'package:chrysalis_mobile/features/profile/domain/repository/profile_repository.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/change_password_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/get_user_profile_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/toggle_notifications_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/update_profile_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/data/remote/search_group_remote_service.dart';
import 'package:chrysalis_mobile/features/search_groups/data/repository/search_group_repository_impl.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/repository/search_group_repository.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/add_group_to_recent_search_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/get_recent_search_groups_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/search_groups_by_text_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  sl
    // Core
    ..registerLazySingleton<DioClient>(DioClient.new)
    ..registerLazySingleton<LocalStorage>(LocalStorage.new)
    // Remote Service
    ..registerLazySingleton<AuthRemoteService>(
      () => AuthRemoteServiceImpl(sl<DioClient>()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<AuthRemoteService>()),
    )
    // Use Cases
    ..registerLazySingleton(() => LoginUseCase(sl()))
    ..registerLazySingleton(() => LogoutUseCase(sl()))
    // Search Groups Feature
    ..registerLazySingleton<SearchGroupRemoteService>(
      () => SearchGroupRemoteService(sl<DioClient>()),
    )
    ..registerLazySingleton<SearchGroupRepository>(
      () => SearchGroupRepositoryImpl(sl<SearchGroupRemoteService>()),
    )
    ..registerLazySingleton<GetRecentSearchGroupsUseCase>(
      () => GetRecentSearchGroupsUseCase(sl<SearchGroupRepository>()),
    )
    ..registerLazySingleton<SearchGroupsByTextUseCase>(
      () => SearchGroupsByTextUseCase(sl<SearchGroupRepository>()),
    )
    ..registerLazySingleton<AddGroupToRecentSearchUseCase>(
      () => AddGroupToRecentSearchUseCase(sl<SearchGroupRepository>()),
    )
    // Homepage Feature
    ..registerLazySingleton<HomeRemoteService>(
      () => HomeRemoteServiceImpl(sl<DioClient>()),
    )
    ..registerLazySingleton<HomeLocalDataSource>(
      () => HomeLocalDataSourceImpl(sl<Box<String>>()),
    )
    ..registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        sl<HomeRemoteService>(),
        sl<HomeLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<GetHomeDataUseCase>(
      () => GetHomeDataUseCase(sl<HomeRepository>()),
    )
    ..registerLazySingleton<MarkAllAsReadUseCase>(
      () => MarkAllAsReadUseCase(sl<HomeRepository>()),
    )
    ..registerLazySingleton<SocketService>(SocketService.new)
    ..registerFactory(() => SocketConnectionCubit(sl<SocketService>()))
    // Chat Detail Feature
    ..registerLazySingleton<ChatDetailRemoteService>(
      () => ChatDetailRemoteServiceImpl(sl<DioClient>()),
    )
    ..registerLazySingleton<Box<String>>(
      () => Hive.box<String>(AppKeys.chatBox),
    )
    ..registerLazySingleton<ChatDetailLocalDataSource>(
      () => ChatDetailLocalDataSourceImpl(sl<Box<String>>()),
    )
    ..registerLazySingleton<ChatDetailRepository>(
      () => ChatDetailRepositoryImpl(
        sl<ChatDetailRemoteService>(),
        sl<ChatDetailLocalDataSource>(),
      ),
    )
    ..registerLazySingleton<GetMessagesUseCase>(
      () => GetMessagesUseCase(sl<ChatDetailRepository>()),
    )
    ..registerLazySingleton(
      () => SendMessageUseCase(sl<ChatDetailRepository>()),
    )
    // Profile Feature
    ..registerLazySingleton<ProfileRemoteService>(
      () => ProfileRemoteServiceImpl(sl<DioClient>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl<ProfileRemoteService>()),
    )
    ..registerLazySingleton<GetUserProfileUseCase>(
      () => GetUserProfileUseCase(sl<ProfileRepository>()),
    )
    ..registerLazySingleton<ChangePasswordUsecase>(
      () => ChangePasswordUsecase(sl<ProfileRepository>()),
    )
    ..registerLazySingleton<ToggleNotificationsUsecase>(
      () => ToggleNotificationsUsecase(sl<ProfileRepository>()),
    )
    ..registerLazySingleton<UpdateProfileUsecase>(
      () => UpdateProfileUsecase(sl<ProfileRepository>()),
    )
    ..registerLazySingleton(() => RegisterKeyUsecase(sl<AuthRepository>()));
}
