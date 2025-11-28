import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/widgets/web_custom_text_field.dart';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class SettingsGeneralSection extends StatelessWidget {
  const SettingsGeneralSection({
    super.key,
    required this.nameController,
    required this.idController,
  });

  final TextEditingController nameController;
  final TextEditingController idController;

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

    final fieldPadding = getResponsiveValue(
      mobile: EdgeInsets.symmetric(horizontal: 12.w, vertical: 18.h),
      tablet: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
      desktop: EdgeInsets.symmetric(horizontal: 12.w, vertical: 22.h),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: AppTextStyles.h5bold(
            context,
          ).copyWith(fontSize: sectionTitleSize, color: const Color(0xFF161616)),
        ),
        SizedBox(height: 16.h),
        if (isMobile)
          // Mobile: Single column layout
          Column(
            children: [
              _buildField(
                label: 'Your name',
                controller: nameController,
                hintText: 'Enter your name',
                labelFontSize: labelFontSize,
                contentPadding: fieldPadding,
              ),
              SizedBox(height: 16.h),
              _buildField(
                label: 'ID',
                controller: idController,
                hintText: '@username',
                labelFontSize: labelFontSize,
                contentPadding: fieldPadding,
              ),
            ],
          )
        else
          // Tablet/Desktop: Two columns layout
          Row(
            children: [
              Expanded(
                child: _buildField(
                  label: 'Your name',
                  controller: nameController,
                  hintText: 'Enter your name',
                  labelFontSize: labelFontSize,
                  contentPadding: fieldPadding,
                ),
              ),
              SizedBox(width: 24.w),
              Expanded(
                child: _buildField(
                  label: 'ID',
                  controller: idController,
                  hintText: '@username',
                  labelFontSize: labelFontSize,
                  contentPadding: fieldPadding,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required double labelFontSize,
    required EdgeInsets contentPadding,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (context) => Text(
            label,
            style: AppTextStyles.p1regular(
              context,
            ).copyWith(
              color: const Color(0xFF666666),
              fontSize: labelFontSize,
            ),
          ),
        ),
        SizedBox(height: 8.h),
        WebCustomTextField(
          controller: controller,
          hintText: hintText,
          fillColor: const Color(0xFFF3F3F5),
          borderColor: Colors.transparent,
          borderRadius: 10.r,
          contentPadding: contentPadding,
        ),
      ],
    );
  }
}
