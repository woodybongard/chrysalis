import 'package:chrysalis_mobile/core/bloc/time_ticker_cubit.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/core/widgets/modern_snackbar.dart';
import 'package:chrysalis_mobile/features/authentication/domain/usecase/logout_usecase.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/logout_bloc/logout_bloc.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/repository/chat_detail_repository.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/get_messages_usecase.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/usecase/send_message_usecase.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/bloc/chat_detail_bloc.dart';
import 'package:chrysalis_mobile/features/homepage/domain/usecase/get_home_data_usecase.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/bloc/home_bloc.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/change_password_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/get_user_profile_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/toggle_notifications_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/update_profile_usecase.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/add_group_to_recent_search_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/get_recent_search_groups_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/domain/usecase/search_groups_by_text_usecase.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/bloc/search_group_bloc.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocRegistrar {
  static List<BlocProvider> providers = [

    BlocProvider<LoginBloc>(lazy: false, create: (_) => LoginBloc()),
    BlocProvider<HomeBloc>(
      lazy: false,
      create: (_) => HomeBloc(
        GetHomeDataUseCase(sl()),
      ),
    ),
    BlocProvider<TimeTickerCubit>(
      lazy: false,
      create: (_) => TimeTickerCubit()..start(),
    ),
    BlocProvider<SocketConnectionCubit>(
      lazy: false,
      create: (context) {
        final cubit = sl<SocketConnectionCubit>(
          param1: (String message) => showModernSnackbar(context, message),
        );

        // Auto-connect if already logged in (safe read)
        LocalStorage().read(key: AppKeys.isLoggedIn).then((isLoggedIn) async {
          try {
            if (isLoggedIn == 'true') {
              cubit.connect();
            }
          } catch (e) {
            //print("️ SecureStorage read failed in BlocRegistrar: $e\n$s");
            await LocalStorage().clear(); // clear corrupted storage
          }
        });
        return cubit;
      },
    ),
    BlocProvider<ChatDetailBloc>(
      create: (_) {
        final repository = sl<ChatDetailRepository>();
        return ChatDetailBloc(
          GetMessagesUseCase(repository),
          SendMessageUseCase(repository),
        );
      },
    ),
    BlocProvider<NotificationBloc>(
      lazy: false,
      create: (_) => NotificationBloc(),
    ),
    BlocProvider<LogoutBloc>(
      lazy: false,
      create: (_) => LogoutBloc(sl<LogoutUseCase>()),
    ),
    BlocProvider<SearchGroupBloc>(
      create: (_) => SearchGroupBloc(
        sl<GetRecentSearchGroupsUseCase>(),
        sl<SearchGroupsByTextUseCase>(),
        sl<AddGroupToRecentSearchUseCase>(),
      ),
    ),
    BlocProvider<ProfileBloc>(
      create: (_) => ProfileBloc(
        sl<GetUserProfileUseCase>(),
        sl<ChangePasswordUsecase>(),
        sl<ToggleNotificationsUsecase>(),
        sl<UpdateProfileUsecase>(),
      ),
    ),
    // Web-specific BLoC for chat selection
    if (kIsWeb)
      BlocProvider<WebChatBloc>(
        create: (context) => WebChatBloc(
          chatDetailBloc: context.read<ChatDetailBloc>(),
          homeBloc: context.read<HomeBloc>(),
        ),
      ),
  ];
}
