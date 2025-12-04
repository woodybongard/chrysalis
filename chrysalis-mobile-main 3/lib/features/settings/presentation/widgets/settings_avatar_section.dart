import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsAvatarSection extends StatelessWidget {
  const SettingsAvatarSection({
    super.key,
    this.onCameraIconTap,
    this.userImage,
    this.userName = 'AR',
  });

  final VoidCallback? onCameraIconTap;
  final String? userImage;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 120.h,
        height: 125.h,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            const ProfileAvatarButton(
              size: 110,
              enableNavigation: false,
            ),
            Positioned(
              right: 10.w,
              bottom: 0,
              child: InkWell(
                onTap: onCameraIconTap,
                borderRadius: BorderRadius.circular(22.r),
                child: Container(
                  width: 44.h,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: AppColors.main500,
                    borderRadius: BorderRadius.circular(22.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6.653,
                        offset: const Offset(0, 2.218),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 18.sp,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}