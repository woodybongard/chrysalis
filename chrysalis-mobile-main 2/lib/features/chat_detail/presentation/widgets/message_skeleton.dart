import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class MessageSkeleton extends StatelessWidget {
  const MessageSkeleton({
    super.key,
    this.alignRight = false,
    this.widthFactor = 0.6,
  });
  final bool alignRight;
  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;
    final maxWidth = MediaQuery.of(context).size.width;
    final bubbleWidth = (maxWidth * widthFactor).clamp(80.0, maxWidth * 0.9);

    final borderRadius = alignRight
        ? BorderRadius.only(
            topLeft: Radius.circular(10 * scaleWidth),
            topRight: Radius.circular(10 * scaleWidth),
            bottomLeft: Radius.circular(10 * scaleWidth),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(10 * scaleWidth),
            topRight: Radius.circular(12 * scaleWidth),
            bottomRight: Radius.circular(10 * scaleWidth),
          );

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: bubbleWidth,
        height: 48 * scaleHeight,
        margin: EdgeInsets.symmetric(vertical: 8 * scaleHeight),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
