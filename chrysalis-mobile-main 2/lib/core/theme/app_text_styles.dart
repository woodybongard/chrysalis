import 'package:chrysalis_mobile/core/theme/app_fonts.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

/// Modern text styles following Figma design system patterns
///
/// This class provides a comprehensive set of text styles that align with
/// common design system practices and Figma design tokens.
class AppTextStyles {
  AppTextStyles._();

  // ==================== FIGMA-STYLE METHODS ====================
  /// Figma-style naming for easier design-to-code workflow

  /// P1 Bold - 16px Bold (equivalent to button style)
  static TextStyle p1bold(BuildContext context) => SFProTextStyles.bold(
    fontSize: 16 * context.scaleHeight,
    height: 1.4,
    letterSpacing: -0.3,
  );

  /// P1 Regular - 16px Regular
  static TextStyle p1regular(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 16 * context.scaleHeight,
        height: 1.4,
        letterSpacing: -0.3,
      );

  /// P2 SemiBold - 16px SemiBold
  static TextStyle p2SemiBold(BuildContext context) =>
      SFProTextStyles.semiBold(
        fontSize: 16 * context.scaleHeight,
        height: 1,
        letterSpacing: -0.3,
      );

  /// P3 Regular - 12px Regular
  static TextStyle p3Regular(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 12 * context.scaleHeight,
        height: 1,
        letterSpacing: -0.3,
      );

  /// Body2 Semibold - 14px SemiBold
  static TextStyle body2Semibold(BuildContext context) =>
      SFProTextStyles.semiBold(
        fontSize: 14 * context.scaleHeight,
        height: 1.2,
        letterSpacing: 0,
      );

  /// Caption2 Regular Center - 12px Regular
  static TextStyle caption2RegularCenter(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 12 * context.scaleHeight,
        height: 1,
        letterSpacing: -0.3,
      );

  /// Title Bold 24 - 24px Bold
  static TextStyle titleBold24(BuildContext context) =>
      SFProDisplayStyles.bold(
        fontSize: 24 * context.scaleHeight,
        height: 1.3,
        letterSpacing: 0,
      );

  /// H2 Bold - 28px Bold
  static TextStyle h2bold(BuildContext context) => SFProDisplayStyles.bold(
    fontSize: 28 * context.scaleHeight,
    height: 1.3,
    letterSpacing: 0,
  );

  /// H5 Bold - 18px Bold
  static TextStyle h5bold(BuildContext context) => SFProDisplayStyles.bold(
    fontSize: 18 * context.scaleHeight,
    height: 1,
    letterSpacing: 0,
  );

  /// Caption Semibold 13 - 13px SemiBold
  static TextStyle captionSemibold13(BuildContext context) =>
      SFProTextStyles.semiBold(
        fontSize: 13 * context.scaleHeight,
        height: 1,
        letterSpacing: -0.3,
      );

  /// Caption Regular - 12px Regular
  static TextStyle captionRegular(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 12 * context.scaleHeight,
        height: 1.5,
        letterSpacing: -0.3,
      );

  /// Display Bold 20 - 20px Display Bold (replacing interBold20)
  static TextStyle displayBold20(BuildContext context) => SFProDisplayStyles.bold(
    fontSize: 20 * context.scaleHeight,
    height: 1.5,
    letterSpacing: -0.3,
  );

  /// Anything - Generic 16px Regular (for backward compatibility)
  static TextStyle anything(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 16 * context.scaleHeight,
        height: 1.4,
        letterSpacing: -0.3,
      );

  // ==================== MODERN DESIGN SYSTEM STYLES ====================
  /// Display Large - 57px
  static TextStyle displayLarge(BuildContext context) =>
      SFProDisplayStyles.bold(
        fontSize: 57 * context.scaleHeight,
        height: 1.12,
        letterSpacing: -0.25,
      );

  /// Display Medium - 45px
  static TextStyle displayMedium(BuildContext context) =>
      SFProDisplayStyles.bold(
        fontSize: 45 * context.scaleHeight,
        height: 1.16,
        letterSpacing: 0,
      );

  /// Display Small - 36px
  static TextStyle displaySmall(BuildContext context) =>
      SFProDisplayStyles.bold(
        fontSize: 36 * context.scaleHeight,
        height: 1.22,
        letterSpacing: 0,
      );

  /// Headline Large - 32px
  static TextStyle headlineLarge(BuildContext context) =>
      SFProDisplayStyles.bold(
        fontSize: 32 * context.scaleHeight,
        height: 1.25,
        letterSpacing: 0,
      );

  /// Headline Medium - 28px
  static TextStyle headlineMedium(BuildContext context) =>
      SFProDisplayStyles.semiBold(
        fontSize: 28 * context.scaleHeight,
        height: 1.29,
        letterSpacing: 0,
      );

  /// Headline Small - 24px
  static TextStyle headlineSmall(BuildContext context) =>
      SFProDisplayStyles.semiBold(
        fontSize: 24 * context.scaleHeight,
        height: 1.33,
        letterSpacing: 0,
      );

  /// Title Large - 22px
  static TextStyle titleLarge(BuildContext context) =>
      SFProDisplayStyles.semiBold(
        fontSize: 22 * context.scaleHeight,
        height: 1.27,
        letterSpacing: 0,
      );

  /// Title Medium - 16px
  static TextStyle titleMedium(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 16 * context.scaleHeight,
        height: 1.5,
        letterSpacing: 0.15,
      );

  /// Title Small - 14px
  static TextStyle titleSmall(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 14 * context.scaleHeight,
        height: 1.43,
        letterSpacing: 0.1,
      );

  /// Label Large - 14px
  static TextStyle labelLarge(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 14 * context.scaleHeight,
        height: 1.43,
        letterSpacing: 0.1,
      );

  /// Label Medium - 12px
  static TextStyle labelMedium(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 12 * context.scaleHeight,
        height: 1.33,
        letterSpacing: 0.5,
      );

  /// Label Small - 11px
  static TextStyle labelSmall(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 11 * context.scaleHeight,
        height: 1.45,
        letterSpacing: 0.5,
      );

  /// Body Large - 16px
  static TextStyle bodyLarge(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 16 * context.scaleHeight,
        height: 1.5,
        letterSpacing: 0.5,
      );

  /// Body Medium - 14px
  static TextStyle bodyMedium(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 14 * context.scaleHeight,
        height: 1.43,
        letterSpacing: 0.25,
      );

  /// Body Small - 12px
  static TextStyle bodySmall(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 12 * context.scaleHeight,
        height: 1.33,
        letterSpacing: 0.4,
      );

  /// Button Text - Medium weight, optimized for buttons
  static TextStyle button(BuildContext context) =>
      SFProTextStyles.semiBold(
        fontSize: 16 * context.scaleHeight,
        height: 1.25,
        letterSpacing: 0.1,
      );

  /// Button Small - For smaller buttons
  static TextStyle buttonSmall(BuildContext context) =>
      SFProTextStyles.semiBold(
        fontSize: 14 * context.scaleHeight,
        height: 1.29,
        letterSpacing: 0.1,
      );

  /// Caption - For image captions, legal text, etc.
  static TextStyle caption(BuildContext context) =>
      SFProTextStyles.regular(
        fontSize: 12 * context.scaleHeight,
        height: 1.33,
        letterSpacing: 0.4,
      );

  /// Overline - For category labels, section headers
  static TextStyle overline(BuildContext context) =>
      SFProTextStyles.medium(
        fontSize: 10 * context.scaleHeight,
        height: 1.6,
        letterSpacing: 1.5,
      );

  // ==================== SEMANTIC STYLES ====================
  /// Chat message text
  static TextStyle chatMessage(BuildContext context) => bodyMedium(context);

  /// Chat sender name
  static TextStyle chatSender(BuildContext context) =>
      labelMedium(context).copyWith(fontWeight: AppFontWeights.semiBold);

  /// Chat timestamp
  static TextStyle chatTimestamp(BuildContext context) =>
      caption(context).copyWith(color: Colors.grey[600]);

  /// App bar title
  static TextStyle appBarTitle(BuildContext context) => titleLarge(context);

  /// Navigation label
  static TextStyle navigationLabel(BuildContext context) =>
      labelMedium(context);

  /// Error text
  static TextStyle error(BuildContext context) =>
      bodySmall(context).copyWith(color: Colors.red[700]);

  /// Success text
  static TextStyle success(BuildContext context) =>
      bodySmall(context).copyWith(color: Colors.green[700]);

  /// Warning text
  static TextStyle warning(BuildContext context) =>
      bodySmall(context).copyWith(color: Colors.orange[700]);

  // ==================== UTILITY METHODS ====================

  /// Create a custom style based on an existing style
  static TextStyle custom(
    TextStyle baseStyle, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    String? fontFamily,
  }) {
    return baseStyle.copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      fontFamily: fontFamily,
    );
  }

  /// Apply responsive scaling to any text style
  static TextStyle responsive(
    BuildContext context,
    TextStyle style, {
    double scale = 1.0,
  }) {
    return style.copyWith(
      fontSize: (style.fontSize ?? 16) * context.scaleHeight * scale,
    );
  }

  /// Legacy method for backward compatibility - Returns a copy of the given style with the provided changes.
  static TextStyle withCopyWith(
    TextStyle style, {
    String? fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return style.copyWith(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      decoration: decoration,
    );
  }

  /// Create a style with specific emphasis
  static TextStyle emphasized(
    TextStyle baseStyle, {
    bool bold = false,
    bool italic = false,
    Color? color,
  }) {
    return baseStyle.copyWith(
      fontWeight: bold ? AppFontWeights.bold : baseStyle.fontWeight,
      fontStyle: italic ? FontStyle.italic : baseStyle.fontStyle,
      color: color,
    );
  }
}

/// Extension to add convenient styling methods to TextStyle
extension TextStyleExtensions on TextStyle {
  /// Make this style bold
  TextStyle get bold => copyWith(fontWeight: AppFontWeights.bold);

  /// Make this style italic
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  /// Make this style semi-bold
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeights.semiBold);

  /// Make this style medium weight
  TextStyle get medium => copyWith(fontWeight: AppFontWeights.medium);

  /// Add underline decoration
  TextStyle get underlined => copyWith(decoration: TextDecoration.underline);

  /// Remove any decoration
  TextStyle get plain => copyWith(decoration: TextDecoration.none);

  /// Apply a color
  TextStyle withColor(Color color) => copyWith(color: color);

  /// Apply opacity
  TextStyle withOpacity(double opacity) =>
      copyWith(color: (color ?? Colors.black).withValues(alpha: opacity));

  /// Scale the font size
  TextStyle scaled(double factor) =>
      copyWith(fontSize: (fontSize ?? 16) * factor);
}
