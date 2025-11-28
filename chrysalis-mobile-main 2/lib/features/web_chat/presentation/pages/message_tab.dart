import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/pages/chat_detail_page.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/pages/home_page.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_bloc.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // Calculate responsive dimensions based on screen size
    final containerPadding = getResponsiveValue(
      mobile: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      tablet: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
      desktop: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
    );

    final containerMargin = getResponsiveValue(
      mobile: EdgeInsets.only(right: 16.w, top: 12.h, bottom: 12.h),
      tablet: EdgeInsets.only(right: 24.w, top: 15.h, bottom: 15.h),
      desktop: EdgeInsets.only(right: 30.w, top: 15.h, bottom: 15.h),
    );

    final titleFontSize = getResponsiveValue(
      mobile: 20.sp,
      tablet: 24.sp,
      desktop: 28.sp,
    );

    final sidebarWidth = getResponsiveValue(
      mobile: context.screenWidth, // Full width on mobile for single panel
      tablet: context.screenWidth * 0.4, // 40% of screen on tablet
      desktop: 400.w, // Fixed 400 on desktop
    );

    final sidebarHeaderHeight = getResponsiveValue(
      mobile: 60.h,
      tablet: 65.h,
      desktop: 71.h,
    );

    final sidebarHeaderPadding = getResponsiveValue(
      mobile: EdgeInsets.only(left: 16.w),
      tablet: EdgeInsets.only(left: 20.w),
      desktop: EdgeInsets.only(left: 24.w),
    );

    final headerFontSize = getResponsiveValue(
      mobile: 16.sp,
      tablet: 20.sp,
      desktop: 24.sp,
    );

    final borderRadius = getResponsiveValue(
      mobile: 12.r,
      tablet: 16.r,
      desktop: 20.r,
    );

    final iconSize = getResponsiveValue(
      mobile: 40.sp,
      tablet: 56.sp,
      desktop: 64.sp,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: containerPadding,
        margin: containerMargin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.p2SemiBold(context).copyWith(
                color: AppColors.black,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            SizedBox(
              height: getResponsiveValue(
                mobile: 20.h,
                tablet: 24.h,
                desktop: 29.h,
              ),
            ),
            Expanded(
              child: Container(
                width: double.maxFinite,
                height: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEBEBEB)),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: isMobile ? _buildMobileLayout(
                  borderRadius: borderRadius,
                  sidebarHeaderHeight: sidebarHeaderHeight,
                  sidebarHeaderPadding: sidebarHeaderPadding,
                  headerFontSize: headerFontSize,
                  iconSize: iconSize,
                ) : _buildTabletDesktopLayout(
                  context: context,
                  borderRadius: borderRadius,
                  sidebarWidth: sidebarWidth,
                  sidebarHeaderHeight: sidebarHeaderHeight,
                  sidebarHeaderPadding: sidebarHeaderPadding,
                  headerFontSize: headerFontSize,
                  iconSize: iconSize,
                ),
              ),
            ),
            SizedBox(
              height: getResponsiveValue(
                mobile: 20.h,
                tablet: 28.h,
                desktop: 35.h,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile layout - Single panel that switches between chat list and chat detail
  Widget _buildMobileLayout({
    required double borderRadius,
    required double sidebarHeaderHeight,
    required EdgeInsets sidebarHeaderPadding,
    required double headerFontSize,
    required double iconSize,
  }) {
    return BlocBuilder<WebChatBloc, WebChatState>(
      builder: (context, state) {
        final hasSelectedChat = state.status == WebChatStatus.selected && 
                                state.selectedChat != null;
        
        if (hasSelectedChat) {
          // Show chat detail with back button
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Column(
              children: [
                // Header with back button
                Container(
                  height: sidebarHeaderHeight,
                  width: double.maxFinite,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEBEBEB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebChatBloc>().add(const ClearChatSelectionEvent());
                        },
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 20.sp,
                          color: AppColors.black,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          state.selectedChat?.title ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.p2SemiBold(context).copyWith(
                            color: AppColors.black,
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Chat detail
                Expanded(
                  child: ChatDetailPage(
                    key: ValueKey(state.selectedChat!.id),
                    args: state.selectedChat!,
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show chat list
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: sidebarHeaderHeight,
                  width: double.maxFinite,
                  padding: sidebarHeaderPadding,
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEBEBEB)),
                    ),
                  ),
                  child: Text(
                    textAlign: TextAlign.start,
                    'Recent chats',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.p2SemiBold(context).copyWith(
                      color: AppColors.black,
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const Expanded(
                  child: HomePage(isShowAppBar: false),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Tablet & Desktop layout - Split view with sidebar and chat detail
  Widget _buildTabletDesktopLayout({
    required BuildContext context,
    required double borderRadius,
    required double sidebarWidth,
    required double sidebarHeaderHeight,
    required EdgeInsets sidebarHeaderPadding,
    required double headerFontSize,
    required double iconSize,
  }) {
    return Row(
      children: [
        // Chat list sidebar - responsive width
        ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            bottomLeft: Radius.circular(borderRadius),
          ),
          child: SizedBox(
            width: sidebarWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: sidebarHeaderHeight,
                  width: double.maxFinite,
                  padding: sidebarHeaderPadding,
                  alignment: Alignment.centerLeft,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEBEBEB)),
                    ),
                  ),
                  child: Text(
                    textAlign: TextAlign.start,
                    'Recent chats',
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.p2SemiBold(context).copyWith(
                      color: AppColors.black,
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
                const Expanded(
                  child: HomePage(isShowAppBar: false),
                ),
              ],
            ),
          ),
        ),
        // Divider
        Container(
          width: 1,
          height: double.maxFinite,
          color: const Color(0xFFEBEBEB),
        ),
        // Chat detail section - takes remaining space
        Expanded(
          child: BlocBuilder<WebChatBloc, WebChatState>(
            builder: (context, state) {
              if (state.status == WebChatStatus.selected &&
                  state.selectedChat != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(borderRadius),
                    bottomRight: Radius.circular(borderRadius),
                  ),
                  child: ChatDetailPage(
                    key: ValueKey(state.selectedChat!.id),
                    args: state.selectedChat!,
                  ),
                );
              } else if (state.status == WebChatStatus.error) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: getResponsiveValue(
                          mobile: 32.sp,
                          tablet: 40.sp,
                          desktop: 48.sp,
                        ),
                        color: AppColors.neural300,
                      ),
                      SizedBox(
                        height: getResponsiveValue(
                          mobile: 12.h,
                          tablet: 14.h,
                          desktop: 16.h,
                        ),
                      ),
                      Text(
                        state.errorMessage ?? 'An error occurred',
                        style: AppTextStyles.p2SemiBold(context).copyWith(
                          color: AppColors.neural500,
                          fontSize: getResponsiveValue(
                            mobile: 14.sp,
                            tablet: 16.sp,
                            desktop: 16.sp,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: iconSize,
                        color: AppColors.neural300,
                      ),
                      SizedBox(
                        height: getResponsiveValue(
                          mobile: 12.h,
                          tablet: 14.h,
                          desktop: 16.h,
                        ),
                      ),
                      Text(
                        'Select a chat to start messaging',
                        style: AppTextStyles.p2SemiBold(context).copyWith(
                          color: AppColors.neural500,
                          fontSize: getResponsiveValue(
                            mobile: 14.sp,
                            tablet: 16.sp,
                            desktop: 16.sp,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
