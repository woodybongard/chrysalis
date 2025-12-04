import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsPasswordSection extends StatelessWidget {
  const SettingsPasswordSection({
    super.key,
    required this.onChangePassword,
  });

  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifications preference',
          style: AppTextStyles.h5bold(context).copyWith(
            fontSize: 18.sp,
            color: const Color(0xFF161616),
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: const Color(0xFFEBEBEB),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password',
                    style: AppTextStyles.p1bold(context).copyWith(
                      color: const Color(0xFF010003),
                    ),
                  ),
                  SizedBox(height: 9.h),
                  Text(
                    '***************',
                    style: AppTextStyles.p3Regular(context).copyWith(
                      fontSize: 14.sp,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onChangePassword,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFD7D7D7),
                      width: 0.35,
                    ),
                  ),
                  child: Text(
                    'Change password',
                    style: AppTextStyles.p2SemiBold(context).copyWith(
                      fontSize: 14.sp,
                      color: AppColors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}