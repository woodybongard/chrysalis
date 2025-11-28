import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactAdminUtils {
  static Future<void> launchContactAdmin(BuildContext context) async {
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

    const subject = 'Chrysalis Support Request';
    final body = [
      'App: ${packageInfo.appName}',
      'Version: ${packageInfo.version} (${packageInfo.buildNumber})',
      'Platform: $os $osVersion',
      'Device: $deviceModel',
    ].join('\n');

    final uri = Uri.parse(
      'mailto:woody@btmedical.ca'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
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
