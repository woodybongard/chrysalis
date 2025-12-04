import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class CustomPasswordField extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onVisibilityToggle;
  final Function(String)? onChanged;

  const CustomPasswordField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    required this.obscureText,
    required this.onVisibilityToggle,
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
            obscureText: obscureText,
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
              suffixIcon: GestureDetector(
                onTap: onVisibilityToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: EdgeInsets.only(right: 16 * scaleWidth),
                  child: Icon(
                    obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF8A8A8A),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
