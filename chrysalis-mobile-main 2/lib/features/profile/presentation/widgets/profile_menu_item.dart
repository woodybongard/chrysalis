import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showDivider;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: scaleWidth * 16,
              vertical: scaleHeight * 16,
            ),
            child: Row(
              children: [
                Container(
                  width: scaleWidth * 40,
                  height: scaleWidth * 40,
                  decoration: BoxDecoration(
                    color: iconColor?.withOpacity(0.1) ?? 
                           AppColors.primaryTint1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? AppColors.neural502,
                    size: scaleWidth * 20,
                  ),
                ),
                SizedBox(width: scaleWidth * 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.p1regular(context).copyWith(
                      color: iconColor ?? AppColors.main500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.neural400,
                  size: scaleWidth * 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleWidth * 16),
            child: const Divider(
              height: 1,
              color: AppColors.neural51,
            ),
          ),
      ],
    );
  }
}