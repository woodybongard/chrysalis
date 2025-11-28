import 'package:chrysalis_mobile/core/constants/app_assets.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class InAppNotificationBanner extends StatelessWidget {
  const InAppNotificationBanner({
    super.key,
    this.title,
    this.body,
    this.avatar,
    this.onTap,
  });
  final String? title; // sender name
  final String? body; // message text
  final String? avatar; // message text
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: 8 * scaleWidth,
              vertical: 4 * scaleHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleWidth,
              vertical: 8 * scaleHeight,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(1000), // circular corners
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 6 * scaleWidth,
                  offset: Offset(0, 2 * scaleHeight),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20 * scaleWidth,
                  backgroundColor: AppColors.main500,
                  child: avatar!.isNotEmpty
                      ? Image.network(
                          avatar ?? '',
                          width: 20 * scaleWidth,
                          height: 20 * scaleWidth,
                        )
                      : Image.asset(
                          AppAssets.appLogo,
                          width: 20 * scaleWidth,
                          height: 20 * scaleWidth,
                        ),
                ),
                SizedBox(width: 10 * scaleWidth),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14 * scaleHeight,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2 * scaleHeight),
                      Text(
                        body ?? '',
                        style: TextStyle(
                          fontSize: 13 * scaleHeight,
                          color: AppColors.black.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
