import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_avatar_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_general_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_notifications_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_other_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_password_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:chrysalis_mobile/features/web_chat/presentation/widgets/web_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const String routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _emailNotifications = true;
  bool _hasUnsavedChanges = false;
  String _originalName = '';
  String _originalUsername = '';

  @override
  void initState() {
    super.initState();
    // Load user profile when page initializes
    context.read<ProfileBloc>().add(const LoadUserProfileEvent());
    
    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _idController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _idController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final currentName = _nameController.text;
    final currentUsername = _idController.text;
    
    final hasChanges = currentName != _originalName || currentUsername != _originalUsername;
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  List<String> _splitFullName(String fullName) {
    final nameParts = fullName.trim().split(' ');
    if (nameParts.isEmpty) return ['', ''];
    
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
    
    return [firstName, lastName];
  }

  String _cleanUsername(String username) {
    return username.replaceAll('@', '').trim();
  }

  void _saveProfileChanges() {
    final nameParts = _splitFullName(_nameController.text);
    final cleanUsername = _cleanUsername(_idController.text);
    
    context.read<ProfileBloc>().add(
      UpdateProfileEvent(
        firstName: nameParts[0],
        lastName: nameParts[1],
        username: cleanUsername,
      ),
    );
  }

  Future<void> _pickAndUpdateImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final nameParts = _splitFullName(_nameController.text);
        final cleanUsername = _cleanUsername(_idController.text);
        
        // Handle platform differences
        if (!kIsWeb) {
          // On mobile/desktop, create File from path and use image parameter
          final imageFile = File(image.path);
          
          context.read<ProfileBloc>().add(
            UpdateProfileEvent(
              firstName: nameParts[0],
              lastName: nameParts[1],
              username: cleanUsername,
              image: imageFile,
            ),
          );
        } else {
          // On web, use XFile directly (avoids File class limitations)
          context.read<ProfileBloc>().add(
            UpdateProfileEvent(
              firstName: nameParts[0],
              lastName: nameParts[1],
              username: cleanUsername,
              imageFile: image, // Use XFile for web
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return const ChangePasswordDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // Update text controllers when profile data loads
        if (state.hasUser) {
          final user = state.user!;
          final fullName = '${user.firstName} ${user.lastName}';
          final displayUsername = '@${user.username}';
          
          _nameController.text = fullName;
          _idController.text = displayUsername;
          
          // Store original values for change detection
          _originalName = fullName;
          _originalUsername = displayUsername;
          
          // Debug: Check avatar URL
          debugPrint('Settings: User avatar URL: ${user.avatar}');
          
          // Reset unsaved changes flag and sync notification preference from profile
          if (mounted) {
            setState(() {
              _hasUnsavedChanges = false;
              _emailNotifications = user.isNotification;
            });
          }
        }

        // Show success/error messages
        if (state.hasSuccess) {
          // Reset unsaved changes flag after successful save
          if (mounted) {
            setState(() {
              _hasUnsavedChanges = false;
            });
          }
        }
        
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          margin: EdgeInsets.only(right: 12.w, top: 16.h, bottom: 12.h),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 200.w),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28.w,
                        vertical: 28.h,
                      ),
                      child: Column(
                        children: [
                          // Save button (appears when there are unsaved changes)
                          if (_hasUnsavedChanges) ...[
                            _buildSaveButton(state.isProfileUpdateLoading),
                            SizedBox(height: 16.h),
                          ],
                          SettingsAvatarSection(
                            onCameraIconTap: _pickAndUpdateImage,
                            userImage: state.user?.avatar,
                            userName: state.hasUser 
                                ? '${state.user!.firstName} ${state.user!.lastName}'
                                : 'AR',
                          ),
                          SizedBox(height: 24.h),
                          SettingsGeneralSection(
                            nameController: _nameController,
                            idController: _idController,
                          ),
                          _buildDivider(),
                          const SettingsOtherSection(),
                          _buildDivider(),
                          SettingsNotificationsSection(
                            emailNotifications: _emailNotifications,
                            onEmailNotificationsChanged: (value) {
                              setState(() {
                                _emailNotifications = value;
                              });
                              
                              // Update notification preference via ProfileBloc
                              context.read<ProfileBloc>().add(
                                ToggleNotificationsEvent(value),
                              );
                            },
                          ),
                          _buildDivider(),
                          SettingsPasswordSection(
                            onChangePassword: _showChangePasswordDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              86.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(left: 30.w,top: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: AppTextStyles.p2SemiBold(context).copyWith(
              color: AppColors.black,
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading) {
    return Align(
      alignment: Alignment.centerRight,
      child: isLoading 
          ? SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.main500,
              ),
            )
          : TextButton(
              onPressed: _saveProfileChanges,
              child: Text(
                'Save Changes',
                style: AppTextStyles.p1regular(context).copyWith(
                  fontSize: 14.sp,
                  color: AppColors.main500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      child: Container(height: 1, color: const Color(0xFFEBEBEB)),
    );
  }
}
