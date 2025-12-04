import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/pages/login_page.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/pages/terms_conditions_page.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/pages/privacy_policy_page.dart';
import 'package:chrysalis_mobile/features/chat_detail/domain/entity/chat_detail_args.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/pages/chat_detail_page.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/pages/home_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/change_password_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:chrysalis_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:chrysalis_mobile/features/search_groups/presentation/pages/search_group.dart';
import 'package:chrysalis_mobile/features/splash/presentation/pages/splash_page.dart';
import 'package:chrysalis_mobile/features/splash/presentation/pages/welcome_page.dart';
import 'package:chrysalis_mobile/features/settings/presentation/pages/settings_page.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/pages/main_chat.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: kIsWeb ? '${AppRoutes.welcome}/${AppRoutes.signIn}' : AppRoutes.splash,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.welcome,
      name: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
      routes: [
        GoRoute(
          path: 'login',
          name: AppRoutes.signIn,
          builder: (context, state) => const LoginPage(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.home,
      name: AppRoutes.home,
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'chat',
          name: AppRoutes.chatDetail,
          pageBuilder: (context, state) {
            final args = state.extra as ChatDetailArgs?;
            if (args == null) {
              return const MaterialPage(child: WelcomePage());
            }
            return MaterialPage(child: ChatDetailPage(args: args));
          },
        ),
        GoRoute(
          path: 'profile',
          name: AppRoutes.profile,
          builder: (context, state) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'changePassword',
              name: AppRoutes.changePassword,
              builder: (context, state) => const ChangePasswordPage(),
            ),
            GoRoute(
              path: 'editProfile',
              name: AppRoutes.editProfile,
              builder: (context, state) => const ProfileEditPage(),
            ),
          ],
        ),
        GoRoute(
          path: 'search',
          name: AppRoutes.searchContacts,
          builder: (context, state) => const SearchGroupPage(),
        ),
      ],
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
    GoRoute(
      path: AppRoutes.termsConditions,
      name: AppRoutes.termsConditions,
      builder: (context, state) => const TermsConditionsPage(),
    ),
    GoRoute(
      path: AppRoutes.privacyPolicy,
      name: AppRoutes.privacyPolicy,
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
  ],
  errorBuilder: (context, state) => const WelcomePage(),
);
