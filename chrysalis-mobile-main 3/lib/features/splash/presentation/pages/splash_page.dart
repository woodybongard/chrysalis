import 'dart:developer';

import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/constants/app_keys.dart';
import 'package:chrysalis_mobile/core/crypto_services/crypto_service.dart';
import 'package:chrysalis_mobile/core/local_storage/local_storage.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final storage = LocalStorage();
    try {
      final isLoggedIn = await storage.read(key: AppKeys.isLoggedIn);
      log('Splash: User is logged in: $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn == 'true') {
        // User is logged in, load keys and go to home
        await CryptoService().loadKeys();
        if (!mounted) return;
        context.read<SocketConnectionCubit>().connect();
        context.go(AppRoutes.home);
      } else {
        // User is not logged in, go to welcome page
        context.go(AppRoutes.welcome);
      }
    } catch (e) {
      log('Splash: Error checking auth: $e');
      await storage.clear();
      if (!mounted) return;
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Image.asset(
          AppAssets.appLogo,
          width: 80,
          height: 80,
        ),
      ),
    );
  }
}
