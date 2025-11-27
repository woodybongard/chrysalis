import 'dart:io';

import 'package:chrysalis_mobile/app/bootstrap.dart';
import 'package:chrysalis_mobile/app/view/app.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/di/service_locator.dart';
import 'package:chrysalis_mobile/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable HTTP calls for development/testing
  // HttpOverrides.global = MyHttpOverrides();
  
  // Use path URL strategy on web to remove the # from URLs
  usePathUrlStrategy();
  await Hive.initFlutter();
  await Hive.openBox<String>(AppKeys.chatBox);
  await initServiceLocator();

  await dotenv.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await bootstrap(() => const App());
}
