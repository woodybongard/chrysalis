import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/widgets/web_custom_button.dart';
import 'package:chrysalis_mobile/core/widgets/web_custom_text_field.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (!mounted) return;
        
        if (state.hasSuccess && !state.isPasswordChangeLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state.hasError && !state.isPasswordChangeLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 575.w,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                SizedBox(height: 32.h),
                _buildPasswordFields(),
                SizedBox(height: 40.h),
                _buildChangePasswordButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change password',
                style: AppTextStyles.h2bold(context).copyWith(
                  fontSize: 24.sp,
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Your password must be a strong combination of letters, alphabets and numbers.',
                style: AppTextStyles.p1regular(context).copyWith(
                  color: const Color(0xFF686868),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 24.w),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: 32.w,
            height: 32.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.close,
              size: 20.sp,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _buildPasswordField(
          label: 'Current password',
          controller: _currentPasswordController,
          hintText: '**************',
          isVisible: _isCurrentPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
            });
          },
        ),
        SizedBox(height: 24.h),
        _buildPasswordField(
          label: 'New password',
          controller: _newPasswordController,
          hintText: 'Enter new password',
          isVisible: _isNewPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isNewPasswordVisible = !_isNewPasswordVisible;
            });
          },
        ),
        SizedBox(height: 24.h),
        _buildPasswordField(
          label: 'Confirm password',
          controller: _confirmPasswordController,
          hintText: 'Re-enter your password',
          isVisible: _isConfirmPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.p1regular(context).copyWith(
            color: const Color(0xFF686868),
            fontSize: 16.sp,
            height: 1.4,
          ),
        ),
        SizedBox(height: 12.h),
        WebCustomTextField(
          controller: controller,
          hintText: hintText,
          obscureText: !isVisible,
          fillColor: AppColors.white,
          borderColor: const Color(0xFFE9E9E9),
          borderRadius: 8.r,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 18.h,
          ),
          textStyle: AppTextStyles.p1regular(context).copyWith(
            color: const Color(0xFF4B4B4B),
            fontSize: 14.sp,
            height: 1.4,
          ),
          hintStyle: AppTextStyles.p1regular(context).copyWith(
            color: const Color(0xFF9F9D9F),
            fontSize: 14.sp,
            height: 1.4,
          ),
          suffixIcon: IconButton(
            onPressed: onVisibilityToggle,
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              size: 20.sp,
              color: const Color(0xFF686868),
          ),
          ),
        ),
      ],
    );
  }

  void _handleChangePassword() {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter current password')),
      );
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter new password')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 8 characters')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Use ProfileBloc to change password
    context.read<ProfileBloc>().add(
      ChangePasswordEvent(_currentPasswordController.text, _newPasswordController.text),
    );
  }

  Widget _buildChangePasswordButton() {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        return WebCustomButton(
          text: 'Change password',
          onPressed: state.isPasswordChangeLoading ? null : _handleChangePassword,
          isLoading: state.isPasswordChangeLoading,
          width: 535.w,
          height: 52.h,
          borderRadius: 12.r,
          textStyle: AppTextStyles.h5bold(context).copyWith(
            fontSize: 16.sp,
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}