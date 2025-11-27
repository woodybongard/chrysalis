import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileHeader extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final String displayName;
  final String username;

  const ProfileHeader({
    super.key,
    this.imageUrl,
    required this.initials,
    required this.displayName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return GestureDetector(
      onTap: () {
        context.goNamed(AppRoutes.editProfile);
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: scaleHeight * 24),
            ProfileAvatar(
              imageUrl: imageUrl,
              initials: initials,
              size: 100,
            ),
            SizedBox(height: scaleHeight * 16),
            Text(
              displayName,
              style: AppTextStyles.headlineMedium(context).copyWith(
                color: AppColors.main500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: scaleHeight * 4),
            Text(
              '@$username',
              style: AppTextStyles.p3Regular(context).copyWith(
                color: AppColors.neural400,
              ),
            ),
            SizedBox(height: scaleHeight * 24),
          ],
        ),
      ),
    );
  }
}