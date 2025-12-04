import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Toast utility class that supports both web and mobile platforms
/// Uses Fluttertoast package which internally uses Toastify-JS for web
class ToastUtils {
  static late FToast _fToast;
  static bool _isInitialized = false;

  /// Initialize toast with context
  /// Should be called once in the app, preferably in the main widget
  static void init(BuildContext context) {
    _fToast = FToast();
    _fToast.init(context);
    _isInitialized = true;
  }

  /// Show success toast with green background
  static void showSuccess({
    required String message,
    BuildContext? context,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int duration = 3,
  }) {
    _showToast(
      message: message,
      backgroundColor: AppColors.primaryMain,
      textColor: Colors.white,
      context: context,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// Show error toast with red background
  static void showError({
    required String message,
    BuildContext? context,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int duration = 4,
    bool isLocalized = false,
  }) {
    final displayMessage = isLocalized && context != null 
        ? Translator.translate(context, message)
        : message;
    
    _showToast(
      message: displayMessage,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      context: context,
      icon: Icons.error,
      duration: duration,
    );
  }

  /// Show warning toast with orange background
  static void showWarning({
    required String message,
    BuildContext? context,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int duration = 3,
  }) {
    _showToast(
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
      context: context,
      icon: Icons.warning,
      duration: duration,
    );
  }

  /// Show info toast with blue background
  static void showInfo({
    required String message,
    BuildContext? context,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int duration = 3,
  }) {
    _showToast(
      message: message,
      backgroundColor: AppColors.primaryMain,
      textColor: Colors.white,
      context: context,
      icon: Icons.info,
      duration: duration,
    );
  }

  /// Show custom toast with custom styling
  static void showCustom({
    required String message,
    BuildContext? context,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    IconData? icon,
    ToastGravity gravity = ToastGravity.BOTTOM,
    int duration = 3,
  }) {
    _showToast(
      message: message,
      backgroundColor: backgroundColor,
      textColor: textColor,
      context: context,
      icon: icon,
      duration: duration,
    );
  }

  /// Show localized error message based on error type
  static void showLocalizedError({
    required dynamic error,
    BuildContext? context,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    final errorKey = _getErrorKey(error);
    final message = context != null 
        ? Translator.translate(context, errorKey)
        : _getDefaultErrorMessage(error);
    
    showError(
      message: message,
      context: context,
    );
  }

  /// Private method to show toast
  static void _showToast({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    BuildContext? context,
    IconData? icon,
    int duration = 3,
  }) {
    // If context is provided and FToast is initialized, use custom widget
    if (context != null && _isInitialized) {
      _fToast..removeCustomToast()
      ..showToast(
        child: _buildCustomToastWidget(
          message: message,
          backgroundColor: backgroundColor,
          textColor: textColor,
          icon: icon,
        ),
        gravity: ToastGravity.BOTTOM,
        toastDuration: Duration(seconds: duration),
      );
    } else {
      // Fallback to simple Fluttertoast
      Fluttertoast.showToast(
        msg: message,
        toastLength: duration > 3 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: duration,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: 14,
        webBgColor: _colorToHex(backgroundColor),
        webPosition: 'center',
        webShowClose: true,

      );
    }
  }

  /// Build custom toast widget for better UI
  static Widget _buildCustomToastWidget({
    required String message,
    required Color backgroundColor,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: textColor,
              size: 24,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Convert Flutter Color to hex string for web
  static String _colorToHex(Color color) {
    return '#${((color.r * 255).round() & 0xff).toRadixString(16).padLeft(2, '0')}${((color.g * 255).round() & 0xff).toRadixString(16).padLeft(2, '0')}${((color.b * 255).round() & 0xff).toRadixString(16).padLeft(2, '0')}';
  }

  /// Get error key for localization based on error type
  static String _getErrorKey(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('timeout')) {
      return 'error_request_timeout';
    } else if (errorString.contains('no internet') || errorString.contains('connection')) {
      return 'error_no_internet';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'error_unauthorized';
    } else if (errorString.contains('forbidden') || errorString.contains('403')) {
      return 'error_forbidden';
    } else if (errorString.contains('not found') || errorString.contains('404')) {
      return 'error_not_found';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'error_server';
    } 
    // Authentication errors
    else if (errorString.contains('invalid credentials') || errorString.contains('wrong password')) {
      return 'error_invalid_credentials';
    } else if (errorString.contains('session expired')) {
      return 'error_session_expired';
    }
    // Validation errors
    else if (errorString.contains('invalid') || errorString.contains('validation')) {
      return 'error_validation';
    }
    // File errors
    else if (errorString.contains('file size')) {
      return 'error_file_too_large';
    } else if (errorString.contains('file type')) {
      return 'error_invalid_file_type';
    }
    // Default
    else {
      return 'error_general';
    }
  }

  /// Get default error message when localization is not available
  static String _getDefaultErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (errorString.contains('no internet') || errorString.contains('connection')) {
      return 'No internet connection. Please check your network.';
    } else if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'You are not authorized to perform this action.';
    } else if (errorString.contains('session expired')) {
      return 'Your session has expired. Please login again.';
    } else if (errorString.contains('invalid credentials')) {
      return 'Invalid username or password.';
    } else if (errorString.contains('server') || errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (errorString.contains('file size')) {
      return 'File size is too large.';
    } else if (errorString.contains('file type')) {
      return 'Invalid file type.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Cancel all toasts
  static void cancelAll() {
    if (_isInitialized) {
      _fToast.removeCustomToast();
    }
    Fluttertoast.cancel();
  }
}