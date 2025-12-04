import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class CustomProfileTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final Function(String)? onChanged;

  const CustomProfileTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w400,
            fontSize: 16,
            height: 1.4,
            letterSpacing: -0.3,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6 * scaleHeight),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE7E7E7),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.4,
              letterSpacing: -0.3,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                fontFamily: 'SF Pro Text',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 1.4,
                letterSpacing: -0.3,
                color: Color(0xFF8A8A8A),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16 * scaleWidth,
                vertical: 14 * scaleHeight,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
