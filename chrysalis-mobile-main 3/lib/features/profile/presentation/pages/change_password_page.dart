import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/change_password_app_bar.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/custom_password_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _currentPassword.isNotEmpty && 
           _newPassword.isNotEmpty && 
           _newPassword.length >= 8 &&
           _confirmPassword.isNotEmpty &&
           _newPassword == _confirmPassword;
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

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
          // Use a small delay to ensure the snackbar is shown before navigation
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) context.pop();
          });
        } else if (state.hasError && !state.isPasswordChangeLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const ChangePasswordAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
                  child: Column(
                    children: [
                      SizedBox(height: 24 * scaleHeight),
                      
                      // Current Password Field
                      CustomPasswordField(
                        label: 'Current password',
                        placeholder: 'Enter password',
                        controller: _currentPasswordController,
                        obscureText: _obscureCurrentPassword,
                        onVisibilityToggle: () {
                          setState(() {
                            _obscureCurrentPassword = !_obscureCurrentPassword;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _currentPassword = value;
                          });
                        },
                      ),
                      
                      SizedBox(height: 24 * scaleHeight),
                      
                      // New Password Field
                      CustomPasswordField(
                        label: 'New password',
                        placeholder: 'Enter password',
                        controller: _newPasswordController,
                        obscureText: _obscureNewPassword,
                        onVisibilityToggle: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _newPassword = value;
                          });
                        },
                      ),
                      
                      SizedBox(height: 24 * scaleHeight),
                      
                      // Confirm New Password Field
                      CustomPasswordField(
                        label: 'Confirm new password',
                        placeholder: 'Enter password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onVisibilityToggle: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        onChanged: (value) {
                          setState(() {
                            _confirmPassword = value;
                          });
                        },
                      ),
                      
                      SizedBox(height: 48 * scaleHeight),
                    ],
                  ),
                ),
              ),
              
              // Update Password Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
                child: Column(
                  children: [
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        final isLoading = state.isPasswordChangeLoading;
                        
                        return Container(
                          width: double.infinity,
                          height: 52 * scaleHeight,
                          decoration: BoxDecoration(
                            color: _isFormValid && !isLoading 
                                ? const Color(0xFF25253D) 
                                : const Color(0xFF25253D).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isFormValid && !isLoading
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      context.read<ProfileBloc>().add(
                                        ChangePasswordEvent(_currentPassword, _newPassword),
                                      );
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(100),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Update password',
                                        style: AppTextStyles.button(context).copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 32 * scaleHeight),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
