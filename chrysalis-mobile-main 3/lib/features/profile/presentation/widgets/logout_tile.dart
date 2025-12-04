import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const LogoutTile({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return InkWell(
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
                color: AppColors.failedMessageColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                color: AppColors.failedMessageColor,
                size: scaleWidth * 20,
              ),
            ),
            SizedBox(width: scaleWidth * 16),
            Text(
              'Logout',
              style: AppTextStyles.p2SemiBold(context).copyWith(
                color: AppColors.failedMessageColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}