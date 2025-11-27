import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WebCustomTextField extends StatelessWidget {
  const WebCustomTextField({
    required this.hintText,
    super.key,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.keyboardType,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.fillColor,
    this.filled,
    this.contentPadding,
    this.hintStyle,
    this.textStyle,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.cursorColor,
    this.label,
    this.labelStyle,
    this.errorText,
    this.helperText,
    this.helperStyle,
    this.counterText,
    this.prefixText,
    this.suffixText,
    this.prefixStyle,
    this.suffixStyle,
  });
  
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? fillColor;
  final bool? filled;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enableSuggestions;
  final bool autocorrect;
  final Color? cursorColor;
  final String? label;
  final TextStyle? labelStyle;
  final String? errorText;
  final String? helperText;
  final TextStyle? helperStyle;
  final String? counterText;
  final String? prefixText;
  final String? suffixText;
  final TextStyle? prefixStyle;
  final TextStyle? suffixStyle;

  @override
  Widget build(BuildContext context) {
    // Default values using ScreenUtil with specific design requirements
    final defaultBorderRadius = borderRadius ?? 12.r;
    final defaultBorderWidth = borderWidth ?? 0.5;
    final defaultBorderColor = borderColor ?? AppColors.textFieldStroke;
    final defaultFocusedBorderColor = focusedBorderColor ?? AppColors.main500;
    final defaultErrorBorderColor = errorBorderColor ?? Colors.red;
    final defaultFillColor = fillColor ?? AppColors.webTextFieldFillColor;
    final defaultContentPadding = contentPadding ?? EdgeInsets.symmetric(
      vertical: 10.h,
      horizontal: 12.w,
    );
    
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      textInputAction: textInputAction,
      autofocus: autofocus,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      cursorColor: cursorColor,
      style: textStyle ?? AppTextStyles.p1regular(context),
      decoration: InputDecoration(
        // Text fields
        hintText: hintText,
        hintStyle: hintStyle ?? AppTextStyles.p1regular(
          context,
        ).copyWith(color: AppColors.neural400),
        labelText: label,
        labelStyle: labelStyle,
        errorText: errorText,
        helperText: helperText,
        helperStyle: helperStyle,
        counterText: counterText,
        prefixText: prefixText,
        suffixText: suffixText,
        prefixStyle: prefixStyle,
        suffixStyle: suffixStyle,
        
        // Icons
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        prefixIconConstraints: const BoxConstraints(),
        suffixIconConstraints: const BoxConstraints(),
        
        // Padding
        contentPadding: defaultContentPadding,
        isDense: true,
        
        // Fill - always filled with default color
        filled: filled ?? true,
        fillColor: defaultFillColor,
        hoverColor: defaultFillColor,
        focusColor: defaultFillColor,
        
        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultFocusedBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultErrorBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultErrorBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultBorderColor.withAlpha(128),
            width: defaultBorderWidth,
          ),
        ),
      ),
    );
  }
}
