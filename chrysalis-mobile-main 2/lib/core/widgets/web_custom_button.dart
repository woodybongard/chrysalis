import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WebCustomButton extends StatelessWidget {
  const WebCustomButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.filled = true,
    this.width,
    this.height,
    this.borderRadius,
    this.textStyle,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool filled;
  final double? width;
  final double? height;
  final double? borderRadius;
  final TextStyle? textStyle;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      child: filled
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main500,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    borderRadius ?? 32.r,
                  ),
                ),
                textStyle:
                    textStyle ??
                    AppTextStyles.p1bold(
                      context,
                    ).copyWith(color: AppColors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      height: 1.3,),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Text(
                      text,
                    ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: Colors.white, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    borderRadius ?? 32.r,
                  ),
                ),
                textStyle:
                    textStyle ??
                    AppTextStyles.p1bold(context).copyWith(
                      color: AppColors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20.h,
                      width: 20.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Text(text),
            ),
    );
  }
}