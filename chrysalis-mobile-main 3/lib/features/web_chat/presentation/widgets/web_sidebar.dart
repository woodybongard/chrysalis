import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/logout_bloc/logout_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WebSidebar extends StatelessWidget {
  const WebSidebar({super.key, this.selectedIndex = 0, this.onTabSelected});

  final int selectedIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutBloc, LogoutState>(
      listener: (context, state) {
        if (state is LogoutSuccess) {
          context.go(AppRoutes.signIn);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 24.h),

            ProfileAvatarButton(size: 44.w),

            SizedBox(height: 24.h),

            // Messages Icon
            _buildMessagesNavItem(
              isActive: selectedIndex == 0,
              onTap: () {
                onTabSelected?.call(0);
              },
            ),

            SizedBox(height: 24.h),

            // Settings Icon
            _buildSettingsNavItem(
              isActive: selectedIndex == 1,
              onTap: () {
                onTabSelected?.call(1);
              },
            ),

            const Spacer(),

            IconButton(
              onPressed: () {
                context.read<LogoutBloc>().add(LogoutRequested());
              },
              icon: SvgPicture.asset(Assets.iconsIcLogout),
            ),

            SizedBox(height: 34.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesNavItem({
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),

      child: Container(
        width: 44.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isActive ? AppColors.main500 : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(10.w),
        child: SvgPicture.asset(
          Assets.iconsIcMessage,
          width: 20.w,
          height: 20.h,
          colorFilter: ColorFilter.mode(
            isActive ? AppColors.white : AppColors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsNavItem({
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 44.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: isActive ? AppColors.main500 : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(10.w),
        child: SvgPicture.asset(
          isActive ? Assets.iconsIcSettingFilled : Assets.iconsIcSetting,
          width: 20.w,
          height: 20.h,
        ),
      ),
    );
  }
}
