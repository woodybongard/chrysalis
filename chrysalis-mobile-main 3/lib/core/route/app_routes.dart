import 'package:flutter/cupertino.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const String defaultRoute = '/';
  static const String signUp = '/signUp';
  static const String signIn = 'login';
  static const String home = '/home';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  // Child routes of home (relative paths for router, full paths for navigation)
  static const String searchContacts = 'search';
  static const String chatDetail = 'chat';
  static const String profile = 'profile';
  static const String changePassword = 'changePassword';
  static const String editProfile = 'editProfile';
  // Full paths for navigation
  static const String chatDetailPath = '/home/chat';
  static const String searchContactsPath = '/home/search';
  static const String profilePath = '/home/profile';
  // Other routes
  static const String webMainChat = '/chat';
  static const String settings = '/settings';
  static const String termsConditions = '/terms-conditions';
  static const String privacyPolicy = '/privacy-policy';
}
