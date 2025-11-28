import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditProfileAppBar extends StatelessWidget {
  const EditProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Container(
      height: 65 * scaleHeight,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scaleWidth,
        vertical: 16 * scaleHeight,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit profile',
              style: TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.0,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Empty space to balance the layout
          const SizedBox(width: 24, height: 24),
        ],
      ),
    );
  }
}
