import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationRemoteService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    try {
      // Skip Firebase Messaging on web to avoid compatibility issues
      if (kIsWeb) {
        // Return empty string for web platform
        return '';
      }
      
      // For iOS, check if APNS token is available first
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          // APNS token not available yet, return null or handle accordingly
          print('APNS token not available yet');
          return null;
        }
      }
      
      // Get FCM token for mobile platforms
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
}
