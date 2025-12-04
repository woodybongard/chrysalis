// DEPRECATED: This file is kept for backward compatibility
// Use ToastUtils from 'package:chrysalis_mobile/core/utils/toast_utils.dart' instead

import 'package:flutter/material.dart';
import 'package:chrysalis_mobile/core/utils/toast_utils.dart';

/// @deprecated Use ToastUtils.showError() instead
@Deprecated('Use ToastUtils.showError() for error messages or ToastUtils.showLocalizedError() for localized errors')
void showModernSnackbar(BuildContext context, String message) {
  // Fallback to new toast implementation
  ToastUtils.showError(message: message, context: context);
}
