import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomePageShimmer extends StatelessWidget {
  const HomePageShimmer({this.itemCount = 10, super.key});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: scaleHeight * 16),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding: EdgeInsets.only(
              left: scaleWidth * 17.0,
              right: scaleWidth * 17.0,
              top: scaleHeight * 12.0,
            ),
            child: Row(
              children: [
                // Avatar shimmer
                Container(
                  width: scaleWidth * 48,
                  height: scaleWidth * 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: scaleWidth * 12),
                // Text shimmer
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: scaleWidth * 120,
                        height: scaleHeight * 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(height: scaleHeight * 8),
                      Row(
                        children: [
                          Container(
                            width: scaleWidth * 24,
                            height: scaleHeight * 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          SizedBox(width: scaleWidth * 8),
                          Container(
                            width: scaleWidth * 80,
                            height: scaleHeight * 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: scaleWidth * 12),
                // Trailing shimmer
                Container(
                  width: scaleWidth * 32,
                  height: scaleHeight * 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
