import 'package:flutter/cupertino.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

abstract class AppRoutes {
  static const String defaultRoute = '/';
  static const String signUp = '/signUp';
  static const String signIn = '/login';
  static const String home = '/home';
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String searchContacts = '/searchContacts';
  static const String chatDetail = '/chatDetail';
  static const String profile = '/profile';
  static const String changePassword = '/changePassword';
  static const String editProfile = '/editProfile';
  static const String webMainChat = '/chat';
  static const String settings = '/settings';
  static const String termsConditions = '/terms-conditions';
  static const String privacyPolicy = '/privacy-policy';
}
