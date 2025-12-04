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
        return _buildShimmerItem(scaleWidth, scaleHeight);
      },
    );
  }

  Widget _buildShimmerItem(double scaleWidth, double scaleHeight) {
    return Row(
      children: [
        // Avatar - 44x44 to match tile
        Container(
          width: 44 * scaleWidth,
          height: 44 * scaleWidth,
          decoration: const BoxDecoration(
            color: AppColors.neural100,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 12 * scaleWidth),
        // Text placeholder
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140 * scaleWidth,
                height: 14 * scaleHeight,
                decoration: BoxDecoration(
                  color: AppColors.neural100,
                  borderRadius: BorderRadius.circular(4 * scaleWidth),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
