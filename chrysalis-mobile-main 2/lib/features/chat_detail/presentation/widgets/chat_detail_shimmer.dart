import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/chat_detail/presentation/widgets/message_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatDetailShimmer extends StatelessWidget {
  const ChatDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
              itemCount: 12,
              itemBuilder: (context, index) {
                final alignRight = index.isEven; // alternate alignment
                final widthFactor = 0.45 + (index % 3) * 0.15; // vary widths
                return MessageSkeleton(
                  alignRight: alignRight,
                  widthFactor: widthFactor.clamp(0.4, 0.75),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.neural50),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleWidth,
              vertical: 8 * scaleHeight,
            ),
            decoration: const BoxDecoration(color: Colors.white),

            child: Row(
              children: [
                // Shimmer placeholder for attach icon
                Container(
                  width: 24 * scaleWidth,
                  height: 24 * scaleWidth,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                SizedBox(width: 12 * scaleWidth),

                // Shimmer placeholder for text field
                Expanded(
                  child: Container(
                    height: 40 * scaleHeight,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scaleWidth),

                // Shimmer placeholder for send button
                Container(
                  width: 50 * scaleWidth,
                  height: 30 * scaleHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
