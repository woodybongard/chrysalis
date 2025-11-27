import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TermsSection extends StatelessWidget {
  const TermsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top paragraph text
        Text.rich(
          TextSpan(
            text:
            'By proceeding you acknowledge that you have read,\nunderstood and agree to our ',
            style: AppTextStyles.p1bold(context).copyWith(
              color: AppColors.neural500,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: 'Terms and Conditions.',
                style: AppTextStyles.p1bold(context).copyWith(
                  color: AppColors.neural500,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // handle terms tap
                  },
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Text.rich(
          TextSpan(
            children: [
               TextSpan(
                text: '© 2025 Chrysalis   ',
                style: AppTextStyles.p1bold(context).copyWith(
                  color: AppColors.neural500,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
              TextSpan(
                text: 'Privacy Policy',
                style: AppTextStyles.p1bold(context).copyWith(
                  color: AppColors.neural500,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    // handle privacy policy tap
                  },
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
