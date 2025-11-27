import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomePageLoadingMoreShimmer extends StatelessWidget {
  const HomePageLoadingMoreShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return Padding(
      padding: EdgeInsets.only(
        left: scaleWidth * 4.0,
        right: scaleWidth * 17.0,
        bottom: scaleHeight * 17.0,
        top: scaleHeight * 10.0,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
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
  }
}
