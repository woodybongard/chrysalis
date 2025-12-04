import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;
  static String get socketUrl => dotenv.env['SOCKET_URL']!;
  // Authentication endpoints
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get refreshToken => '$baseUrl/auth/refresh';
  static String get registerKey => '$baseUrl/keys/devices/register-key';
  static String get profile => '$baseUrl/auth/me';
  static String get updatePassword => '$baseUrl/users/update-password';
  static String get toggleNotification => '$baseUrl/users/toggle-notifications';
  static String get updateUserProfile => '$baseUrl/auth/me';
  // Chat endpoints
  static String get chatList => '$baseUrl/messages/chat-list';
  static String get messages => '$baseUrl/messages';
  static String get sendMessage => '$baseUrl/messages/send';
  static String get markAllAsRead => '$baseUrl/messages/mark-all-as-read';
  static String get getRecentGroup => '$baseUrl/search/recent-search';
  static String get searchGroupsByText => '$baseUrl/search';
  static String get addGroupToRecentSearch => '$baseUrl/search/recent-search';
}
