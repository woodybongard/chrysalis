import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Extension to provide additional utility functions on the BuildContext
extension ContextExtensions on BuildContext {
  /// Retrieve the MediaQueryData for the current context
  MediaQueryData get mq => MediaQuery.of(this);

  /// Check device type based on screen width
  bool get isMobile => screenWidth <= 600;

  bool get isTab => screenWidth > 600 && screenWidth <= 1024;

  bool get isDesktop => screenWidth > 1024;

  bool get isWeb => kIsWeb;

  /// Get the height of the status bar
  double get statusBarHeight => mq.padding.top;

  /// Get the screen width and height
  double get screenWidth => mq.size.width;

  double get screenHeight => mq.size.height;

  /// Calculate the screen ratio
  double get screenRatio => screenHeight / screenWidth;

  /// Calculate scaling factors based on the screen size and platform
  double get scaleWidth {
    if (isDesktop) {
      // For desktop/web, use 1440px design width
      return screenWidth / _FigmaFileDetails.desktopWidth;
    } else if (isTab) {
      // For tablet, use 768px design width
      return screenWidth / _FigmaFileDetails.tabletWidth;
    } else {
      // For mobile, use 390px design width
      return screenWidth / _FigmaFileDetails.mobileWidth;
    }
  }

  double get scaleHeight {
    if (isDesktop) {
      // For desktop/web, use 1024px design height
      return screenHeight / _FigmaFileDetails.desktopHeight;
    } else if (isTab) {
      // For tablet, use 1024px design height
      return screenHeight / _FigmaFileDetails.tabletHeight;
    } else {
      // For mobile, use 844px design height
      return screenHeight / _FigmaFileDetails.mobileHeight;
    }
  }

  /// Define pixel scale factors based on the device type
  double get widthPx {
    if (isDesktop) return 1; // No additional scaling for desktop
    if (isTab) return 1.2; // Slight scaling for tablet
    return 1; // Base scaling for mobile
  }

  double get heightPx {
    if (isDesktop) return 1;
    if (isTab) return 1.2;
    return 1;
  }

  double get textPx {
    if (isDesktop) return 1;
    if (isTab) return 1.1; // Slightly larger text on tablets
    return 1;
  }

  /// Calculate a scaling factor for text based on the screen size
  double get scaleText {
    double baseWidth;
    double baseHeight;

    if (isDesktop) {
      baseWidth = _FigmaFileDetails.desktopWidth;
      baseHeight = _FigmaFileDetails.desktopHeight;
    } else if (isTab) {
      baseWidth = _FigmaFileDetails.tabletWidth;
      baseHeight = _FigmaFileDetails.tabletHeight;
    } else {
      baseWidth = _FigmaFileDetails.mobileWidth;
      baseHeight = _FigmaFileDetails.mobileHeight;
    }

    return min(screenWidth / baseWidth, screenHeight / baseHeight);
  }

  /// Calculate percent width and height based on the screen size
  double get percentWidth => screenWidth / 100;

  double get percentHeight => screenHeight / 100;

  /// Method to navigate back and optionally pass data

  /// Method to navigate to a named route and replace the current route
  Future<dynamic> pushNamedReplacement(
    String name, {
    Object? arguments,
  }) async => replace(name, extra: arguments);

  /// Method to navigate to a named route
  Future<dynamic> pushNamed(String name, {Object? arguments}) async =>
      push(name, extra: arguments);

  /// Method to navigate to a named route and clear back stack
  Future<dynamic> pushNamedAndRemoveUntil(
    String name, {
    Object? arguments,
  }) async => go(name, extra: arguments);
}

/// Size and screen properties without using the context extension
class WindowProperties {
  static MediaQueryData mq = MediaQueryData.fromView(
    WidgetsBinding.instance.platformDispatcher.views.single,
  );

  static double get statusBarHeight => mq.padding.top;

  static double get bottomBarHeight => mq.padding.bottom;

  static double get screenWidth => mq.size.width;

  static double get screenHeight => mq.size.height;

  static double get safeScreenHeight =>
      mq.size.height - (statusBarHeight + bottomBarHeight);

  static double get screenRatio => screenHeight / screenWidth;

  static double get widthPx => screenWidth / _FigmaFileDetails.screenWidth;

  static double get heightPx => screenHeight / _FigmaFileDetails.screenHeight;

  static double get textPx => min(
    screenWidth / _FigmaFileDetails.screenWidth,
    screenHeight / _FigmaFileDetails.screenHeight,
  );
}

/// Details of the Figma file used for reference in calculations
class _FigmaFileDetails {
  // Mobile design dimensions (iPhone 14 Pro)
  static const double mobileWidth = 390;
  static const double mobileHeight = 844;

  // Tablet design dimensions (iPad)
  static const double tabletWidth = 768;
  static const double tabletHeight = 1024;

  // Desktop/Web design dimensions
  static const double desktopWidth = 1440;
  static const double desktopHeight = 1024;

  // Legacy properties for backward compatibility
  static const double screenWidth = mobileWidth;
  static const double screenHeight = mobileHeight;
}

/// Function to scale a value based on the screen size and device type
double getScaledSize(double value, {double? customScale}) {
  final screenWidth = WindowProperties.screenWidth;

  // Determine scale based on device type if not provided
  double scale;
  if (customScale != null) {
    scale = customScale;
  } else if (screenWidth > 1024) {
    // Desktop: No additional scaling needed
    scale = 1.0;
  } else if (screenWidth > 600) {
    // Tablet: Moderate scaling
    scale = 1.2;
  } else {
    // Mobile: No additional scaling
    scale = 1.0;
  }

  return value * scale;
}

/// Helper function to get responsive value based on device type
T getResponsiveValue<T>({required T mobile, T? tablet, T? desktop}) {
  final screenWidth = WindowProperties.screenWidth;

  if (screenWidth > 1024 && desktop != null) {
    return desktop;
  } else if (screenWidth > 600 && tablet != null) {
    return tablet;
  } else {
    return mobile;
  }
}
