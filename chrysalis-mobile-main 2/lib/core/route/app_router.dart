import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/pages/chat_detail_page.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/pages/home_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/pages/search_group.dart';
import 'package:chrysalis_mobile/features/splash/presentation/pages/welcome_page.dart';
import 'package:chrysalis_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/pages/main_chat.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: kIsWeb ? AppRoutes.signIn : AppRoutes.welcome,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.welcome,
      name: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      name: AppRoutes.signIn,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.home,
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profile,
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: AppRoutes.changePassword,
              name: AppRoutes.changePassword,
              builder: (context, state) => const ChangePasswordPage(),
            ),
            GoRoute(
              path: AppRoutes.editProfile,
              name: AppRoutes.editProfile,
              builder: (context, state) => const ProfileEditPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.searchContacts,
      name: AppRoutes.searchContacts,
      builder: (context, state) => const SearchGroupPage(),
    ),
    GoRoute(
      path: AppRoutes.chatDetail,
      name: AppRoutes.chatDetail,
      pageBuilder: (context, state) {
        final args = state.extra as ChatDetailArgs?;
        if (args == null) {
          return const NoTransitionPage(child: WelcomePage());
        }
        return NoTransitionPage(child: ChatDetailPage(args: args));
      },
    ),
    GoRoute(
      path: AppRoutes.webMainChat,
      name: AppRoutes.webMainChat,
      builder: (context, state) => const MainChat(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
  errorBuilder: (context, state) => const WelcomePage(),
);
