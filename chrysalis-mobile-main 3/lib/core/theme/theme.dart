import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamily = AppFonts.primary;
  static const String fontFamily2 = AppFonts.secondary;

  static ThemeData get myTheme {
    return ThemeData(
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.main500),
      useMaterial3: true,
    );
  }
}
