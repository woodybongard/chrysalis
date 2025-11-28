import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class PasswordValidationChecklist extends StatelessWidget {
  final String password;

  const PasswordValidationChecklist({
    super.key,
    required this.password,
  });

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get isValid => _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber && _hasSpecialChar;

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Container(
      padding: EdgeInsets.all(scaleWidth * 16),
      decoration: BoxDecoration(
        color: AppColors.neural50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.neural100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements',
            style: AppTextStyles.p2SemiBold(context).copyWith(
              color: AppColors.main500,
            ),
          ),
          SizedBox(height: scaleHeight * 12),
          _buildChecklistItem(
            context,
            'At least 8 characters long',
            _hasMinLength,
          ),
          SizedBox(height: scaleHeight * 8),
          _buildChecklistItem(
            context,
            'Include 1 uppercase letter (A-Z)',
            _hasUppercase,
          ),
          SizedBox(height: scaleHeight * 8),
          _buildChecklistItem(
            context,
            'Include 1 lowercase letter (a-z)',
            _hasLowercase,
          ),
          SizedBox(height: scaleHeight * 8),
          _buildChecklistItem(
            context,
            'Include 1 number (0-9)',
            _hasNumber,
          ),
          SizedBox(height: scaleHeight * 8),
          _buildChecklistItem(
            context,
            'Include 1 special character (!@#\$%^&*)',
            _hasSpecialChar,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    BuildContext context,
    String text,
    bool isValid,
  ) {
    final scaleWidth = context.scaleWidth;

    return Row(
      children: [
        Container(
          width: scaleWidth * 16,
          height: scaleWidth * 16,
          decoration: BoxDecoration(
            color: isValid ? Colors.green : AppColors.neural200,
            shape: BoxShape.circle,
          ),
          child: isValid
              ? Icon(
                  Icons.check,
                  color: AppColors.white,
                  size: scaleWidth * 12,
                )
              : null,
        ),
        SizedBox(width: scaleWidth * 12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.captionRegular(context).copyWith(
              color: AppColors.neural400,
            ),
          ),
        ),
      ],
    );
  }
}