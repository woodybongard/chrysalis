import 'dart:developer';

import 'package:chrysalis_mobile/core/bloc_registrar/bloc_registrar.dart';
import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:chrysalis_mobile/core/route/app_router.dart';
import 'package:chrysalis_mobile/core/theme/theme.dart';
import 'package:chrysalis_mobile/features/notifications/presentation/service/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    NotificationService.initialize(context);
    NotificationService.handleInitialMessage(context);
  }

  Future<void> requestNotificationPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log('User granted provisional notification permission');
    } else {
      log('User declined or has not accepted notification permission');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ScreenUtilInit(
        designSize: const Size(1440, 1024), // Web design dimensions

        builder: (context, child) {
          return MultiBlocProvider(
            providers: BlocRegistrar.providers,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.myTheme,
              supportedLocales: Translator.supportedLanguages,
              localizationsDelegates: const [
                Translator.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              routerConfig: appRouter,
              scaffoldMessengerKey: notificationScaffoldMessengerKey,
            ),
          );
        },
      );
    }
    
    // For mobile platforms, use the existing setup without ScreenUtil
    return MultiBlocProvider(
      providers: BlocRegistrar.providers,
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.myTheme,
        supportedLocales: Translator.supportedLanguages,
        localizationsDelegates: const [
          Translator.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        routerConfig: appRouter,
        scaffoldMessengerKey: notificationScaffoldMessengerKey,
      ),
    );
  }
}
