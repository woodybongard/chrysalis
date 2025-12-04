import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactAdminUtils {
  static Future<void> launchContactAdmin(BuildContext context) async {
    const subject = 'Chrysalis Support Request';
    String body = '';
    
    // For web platform, create a simpler body
    if (kIsWeb) {
      body = [
        'Dear Support Team,',
        '',
        '[Please describe your issue here]',
        '',
        'Browser Information:',
        'Platform: Web',
        'User Agent: ${kIsWeb ? "Web Browser" : "Unknown"}',
      ].join('\n');
    } else {
      // For mobile platforms, get device info
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      final os = Platform.operatingSystem;
      var osVersion = '';
      var deviceModel = '';

      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        osVersion = info.version.release;
        deviceModel = '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        osVersion = info.systemVersion;
        deviceModel = info.utsname.machine;
      }
      
      body = [
        'App: ${packageInfo.appName}',
        'Version: ${packageInfo.version} (${packageInfo.buildNumber})',
        'Platform: $os $osVersion',
        'Device: $deviceModel',
      ].join('\n');
    }

    final uri = Uri.parse(
      'mailto:woody@btmedical.ca'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    try {
      if (kIsWeb) {
        // For web, use platformDefault which will open in a new tab/window
        await launchUrl(
          uri, 
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_blank',
        );
      } else {
        // For mobile, use externalApplication
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Could not launch email client');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email app found. Please contact us at woody@btmedical.ca',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
