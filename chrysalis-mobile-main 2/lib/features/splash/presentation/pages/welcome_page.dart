import 'dart:developer';
import 'dart:io';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    userLoggedIn();
  }

  Future<void> userLoggedIn() async {
    final storage = LocalStorage();
    try {
      final isLoggedIn = await storage.read(key: AppKeys.isLoggedIn);
      log('User is logged in: $isLoggedIn');

      if (isLoggedIn == null) {
        return;
      } else if (isLoggedIn == 'true') {
         await CryptoService().loadKeys();
         if (!mounted) return;
         context.go(AppRoutes.home);
      }
    } catch (e) {
      await storage.clear();
    }
  }

  Future<void> _contactAdmin() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();

    final os = Platform.operatingSystem;
    var osVersion = '';
    var deviceModel = '';

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      osVersion = info.version.release ;
      deviceModel = '${info.manufacturer} ${info.model}';
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      osVersion = info.systemVersion ;
      deviceModel = info.utsname.machine ;
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No email app found. Please contact us at woody@btmedical.ca',
          ),
          duration:  Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.star),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.main500,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24 * scaleWidth,
                  vertical: 19 * scaleHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: scaleWidth * 24.0,
                        right: scaleWidth * 24.0,
                      ),
                      child: Text(
                        Translator.translate(context, 'welcome_title'),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.titleBold24(
                          context,
                        ).copyWith(color: Colors.white),
                      ),
                    ),
                    SizedBox(height: 28 * scaleHeight),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.goNamed(AppRoutes.signIn);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: scaleHeight * 16,
                          ),
                          textStyle: AppTextStyles.p1bold(context),
                        ),
                        child: Text(
                          Translator.translate(context, 'login_button'),
                        ),
                      ),
                    ),
                    SizedBox(height: 12 * scaleHeight),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _contactAdmin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: scaleWidth * 16,
                          ),
                          textStyle: AppTextStyles.p1bold(context),
                        ),
                        child: Text(
                          Translator.translate(context, 'contact_admin'),
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * scaleHeight),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
