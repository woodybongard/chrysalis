import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContactAdminButton extends StatelessWidget {
  const ContactAdminButton({
    required this.svgPath,
    required this.text,
    required this.onTap,
    super.key,
  });

  final String svgPath;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.maxFinite,
        height: 56.h,
        padding:  EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(width: 0.35, color: const Color(0xFFD7D7D7)),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 1),
              blurRadius: 6,
              color: Color(0x0F000000),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(svgPath),
            const SizedBox(width: 8),
            Text(
              text,
              style: AppTextStyles.p1bold(context).copyWith(
                color: AppColors.black,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
