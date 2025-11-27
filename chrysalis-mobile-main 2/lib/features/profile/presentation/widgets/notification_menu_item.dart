import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class NotificationMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final bool showDivider;

  const NotificationMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isEnabled,
    required this.onToggle,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Column(
      children: [
        Container(
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
                  color: AppColors.primaryTint1,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.neural502,
                  size: scaleWidth * 20,
                ),
              ),
              SizedBox(width: scaleWidth * 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.p1regular(context).copyWith(
                    color: AppColors.main500,
                  ),
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.primaryMain,
                inactiveThumbColor: AppColors.neural300,
                inactiveTrackColor: AppColors.neural100,
              ),
            ],
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