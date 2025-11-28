import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsNotificationsSection extends StatelessWidget {
  const SettingsNotificationsSection({
    super.key,
    required this.emailNotifications,
    required this.onEmailNotificationsChanged,
  });

  final bool emailNotifications;
  final ValueChanged<bool> onEmailNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    final sectionTitleSize = getResponsiveValue(
      mobile: 16.sp,
      tablet: 17.sp,
      desktop: 18.sp,
    );

    final cardPadding = getResponsiveValue(
      mobile: EdgeInsets.all(16.r),
      tablet: EdgeInsets.all(18.r),
      desktop: EdgeInsets.all(20.r),
    );

    final titleFontSize = getResponsiveValue(
      mobile: 14.sp,
      tablet: 15.sp,
      desktop: 16.sp,
    );

    final descriptionFontSize = getResponsiveValue(
      mobile: 12.sp,
      tablet: 13.sp,
      desktop: 14.sp,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: AppTextStyles.h5bold(
            context,
          ).copyWith(fontSize: sectionTitleSize, color: const Color(0xFF161616)),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: cardPadding,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email notifications',
                      style: AppTextStyles.p2SemiBold(
                        context,
                      ).copyWith(
                        color: AppColors.black,
                        fontSize: titleFontSize,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Stay updated on changes like cancellations or fulfillment requests.',
                      style: AppTextStyles.p3Regular(context).copyWith(
                        fontSize: descriptionFontSize,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),
              _buildToggleSwitch(
                emailNotifications,
                onEmailNotificationsChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch(bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 50.h,
        height: 24.h,
        decoration: BoxDecoration(
          color: value ? const Color(0xFF31C875) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.h,
            height: 20.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
