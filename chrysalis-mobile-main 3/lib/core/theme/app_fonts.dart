import 'package:flutter/material.dart';

/// Font family constants for the application
class AppFonts {
  AppFonts._();

  // Font Family Names
  static const String sfProDisplay = 'SFProDisplay';
  static const String sfProText = 'SFProText';

  // Primary font family for the app
  static const String primary = sfProText;
  static const String secondary = sfProDisplay;
}

/// Font weight constants
class AppFontWeights {
  AppFontWeights._();

  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

/// Text style builder for SF Pro Display font family
class SFProDisplayStyles {
  SFProDisplayStyles._();

  // Regular variant
  static TextStyle regular({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProDisplay,
    fontWeight: AppFontWeights.regular,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // Medium variant
  static TextStyle medium({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProDisplay,
    fontWeight: AppFontWeights.medium,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // SemiBold variant
  static TextStyle semiBold({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProDisplay,
    fontWeight: AppFontWeights.semiBold,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // Bold variant
  static TextStyle bold({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProDisplay,
    fontWeight: AppFontWeights.bold,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

/// Text style builder for SF Pro Text font family
class SFProTextStyles {
  SFProTextStyles._();

  // Regular variant
  static TextStyle regular({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProText,
    fontWeight: AppFontWeights.regular,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // Medium variant
  static TextStyle medium({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProText,
    fontWeight: AppFontWeights.medium,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // SemiBold variant
  static TextStyle semiBold({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProText,
    fontWeight: AppFontWeights.semiBold,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );

  // Bold variant
  static TextStyle bold({
    double fontSize = 16,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => TextStyle(
    fontFamily: AppFonts.sfProText,
    fontWeight: AppFontWeights.bold,
    fontSize: fontSize,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}
