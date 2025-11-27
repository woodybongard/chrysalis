import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class SearchGroupShimmer extends StatelessWidget {
  const SearchGroupShimmer({this.itemCount = 6, super.key});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.0 * scaleWidth),
      itemCount: itemCount,
      separatorBuilder: (context, index) => SizedBox(height: 16 * scaleHeight),
      itemBuilder: (context, index) {
        return Row(
          children: [
            Container(
              width: 40 * scaleWidth,
              height: 40 * scaleWidth,
              decoration: const BoxDecoration(
                color: AppColors.neural100,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12 * scaleWidth),
            Container(
              width: 120 * scaleWidth,
              height: 16 * scaleHeight,
              decoration: BoxDecoration(
                color: AppColors.neural100,
                borderRadius: BorderRadius.circular(8 * scaleWidth),
              ),
            ),
          ],
        );
      },
    );
  }
}
