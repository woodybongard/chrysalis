import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsOtherSection extends StatelessWidget {
  const SettingsOtherSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    final sectionTitleSize = getResponsiveValue(
      mobile: 16.sp,
      tablet: 17.sp,
      desktop: 18.sp,
    );

    final labelFontSize = getResponsiveValue(
      mobile: 14.sp,
      tablet: 15.sp,
      desktop: 16.sp,
    );

    final valueFontSize = getResponsiveValue(
      mobile: 14.sp,
      tablet: 15.sp,
      desktop: 16.sp,
    );

    final containerHeight = getResponsiveValue(
      mobile: 45.h,
      tablet: 47.h,
      desktop: 50.h,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Other settings',
          style: AppTextStyles.h5bold(context).copyWith(
            fontSize: sectionTitleSize,
            color: const Color(0xFF161616),
          ),
        ),
        SizedBox(height: 16.h),
        if (isMobile)
          // Mobile: Single column layout
          Column(
            children: [
              _buildField(
                label: 'Region',
                value: 'United States',
                containerHeight: containerHeight,
                labelFontSize: labelFontSize,
                valueFontSize: valueFontSize,
              ),
              SizedBox(height: 16.h),
              _buildField(
                label: 'Language',
                value: 'English',
                containerHeight: containerHeight,
                labelFontSize: labelFontSize,
                valueFontSize: valueFontSize,
              ),
            ],
          )
        else
          // Tablet/Desktop: Two columns layout
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Region',
                  value: 'United States',
                  containerHeight: containerHeight,
                  labelFontSize: labelFontSize,
                  valueFontSize: valueFontSize,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildField(
                  label: 'Language',
                  value: 'English',
                  containerHeight: containerHeight,
                  labelFontSize: labelFontSize,
                  valueFontSize: valueFontSize,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required double containerHeight,
    required double labelFontSize,
    required double valueFontSize,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => Text(
            label,
            style: AppTextStyles.p1regular(context).copyWith(
              color: AppColors.black,
              fontSize: labelFontSize,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: containerHeight,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) => Text(
                value,
                style: AppTextStyles.p1regular(context).copyWith(
                  color: AppColors.black,
                  fontSize: valueFontSize,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}