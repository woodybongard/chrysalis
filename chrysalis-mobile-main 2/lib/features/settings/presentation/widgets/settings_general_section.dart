import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General',
          style: AppTextStyles.h5bold(
            context,
          ).copyWith(fontSize: 18.sp, color: const Color(0xFF161616)),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your name',
                    style: AppTextStyles.p1regular(
                      context,
                    ).copyWith(color: const Color(0xFF666666)),
                  ),
                  SizedBox(height: 8.h),
                  WebCustomTextField(
                    controller: nameController,
                    hintText: 'Enter your name',
                    fillColor: const Color(0xFFF3F3F5),
                    borderColor: Colors.transparent,
                    borderRadius: 10.r,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 22.h,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID',
                    style: AppTextStyles.p1regular(
                      context,
                    ).copyWith(color: const Color(0xFF666666)),
                  ),
                  SizedBox(height: 8.h),
                  WebCustomTextField(
                    controller: idController,
                    hintText: '@username',
                    fillColor: const Color(0xFFF3F3F5),
                    borderColor: Colors.transparent,
                    borderRadius: 10.r,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 22.h,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
