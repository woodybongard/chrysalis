import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<String?> getDeviceId() async {
    if (kIsWeb) {
      // For web, use browser info or generate a unique ID
      final webInfo = await _deviceInfo.webBrowserInfo;
      // Create a unique ID based on browser info
      return '${webInfo.browserName}_${webInfo.userAgent?.hashCode ?? DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info
          .id; // ANDROID_ID (unique per device, may reset after factory reset)
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor; // Unique per app vendor on iOS
    }
    return null;
  }
}
