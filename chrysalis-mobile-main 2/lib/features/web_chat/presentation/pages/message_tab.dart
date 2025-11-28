import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/pages/chat_detail_page.dart';
import 'package:chrysalis_mobile/features/homepage/presentation/pages/home_page.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_bloc.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/bloc/web_chat_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 15.h),
        margin: EdgeInsets.only(right: 30.w, top: 15.h, bottom: 15.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.p2SemiBold(context).copyWith(
                color: AppColors.black,
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            29.verticalSpace,
            Expanded(
              child: Container(
                width: double.maxFinite,
                height: double.maxFinite,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEBEBEB)),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),

                      child: SizedBox(
                        width: 400.w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 71.h,
                              width: double.maxFinite,
                              padding: EdgeInsets.only(
                                left: 24.w,
                              ),
                              alignment: Alignment.centerLeft,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color:  Color(0xFFEBEBEB),
                                  ),
                                ),
                              ),
                              child: Text(
                                textAlign: TextAlign.start,
                                'Recent chats',
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.p2SemiBold(context)
                                    .copyWith(
                                      color: AppColors.black,
                                      fontSize: 24.sp,
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
                    // Chat detail section
                    Container(
                      width: 1,
                      height: double.maxFinite,
                      color: const Color(0xFFEBEBEB),
                    ),
                    Expanded(
                      child: BlocBuilder<WebChatBloc, WebChatState>(
                        builder: (context, state) {
                          if (state.status == WebChatStatus.loading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state.status == WebChatStatus.selected &&
                              state.selectedChat != null) {
                            // Show ChatDetailPage when a chat is selected
                            return ClipRRect(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(20.r),
                                bottomRight: Radius.circular(20.r),
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
                                    size: 48.sp,
                                    color: AppColors.neural300,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    state.errorMessage ?? 'An error occurred',
                                    style: AppTextStyles.p2SemiBold(context)
                                        .copyWith(color: AppColors.neural500),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Empty state when no chat is selected
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 64.sp,
                                    color: AppColors.neural300,
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Select a chat to start messaging',
                                    style: AppTextStyles.p2SemiBold(context)
                                        .copyWith(color: AppColors.neural500),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            35.verticalSpace,
          ],
        ),
      ),
    );
  }
}
