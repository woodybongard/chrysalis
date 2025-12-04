import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_avatar_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_general_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_notifications_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_other_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/settings_password_section.dart';
import 'package:chrysalis_mobile/features/settings/presentation/widgets/change_password_dialog.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
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
    if (kIsWeb) {
      // Web: Use file_picker to avoid blob URL issues
      await _pickAndUpdateImageWeb();
    } else {
      // Mobile: Use image_picker as before
      await _pickAndUpdateImageMobile();
    }
  }

  Future<void> _pickAndUpdateImageWeb() async {
    try {
      debugPrint('🌐 Settings: Using file_picker for web image selection');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.bytes != null) {
          debugPrint('✅ Settings Web: File selected - ${file.bytes!.length} bytes');
          
          context.read<ProfileBloc>().add(
            UpdateProfileImageWebEvent(
              imageBytes: file.bytes!,
              fileName: file.name,
              mimeType: _getMimeTypeFromExtension(file.extension),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Settings Web file picker error: $e');
    }
  }

  Future<void> _pickAndUpdateImageMobile() async {
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
        
        // Mobile: Create File from path and use image parameter
        final imageFile = File(image.path);
        
        context.read<ProfileBloc>().add(
          UpdateProfileEvent(
            firstName: nameParts[0],
            lastName: nameParts[1],
            username: cleanUsername,
            image: imageFile,
          ),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  /// Get MIME type from file extension
  String _getMimeTypeFromExtension(String? extension) {
    if (extension == null) return 'image/jpeg';
    
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
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
    // Calculate responsive dimensions
    final containerMargin = getResponsiveValue(
      mobile: EdgeInsets.only(right: 16.w, top: 16.h, bottom: 12.h),
      tablet: EdgeInsets.only(right: 20.w, top: 16.h, bottom: 12.h),
      desktop: EdgeInsets.only(right: 12.w, top: 16.h, bottom: 12.h),
    );

    final contentHorizontalMargin = getResponsiveValue(
      mobile: EdgeInsets.symmetric(horizontal: 16.w), // Small margins on mobile
      tablet: EdgeInsets.symmetric(horizontal: 60.w),  // Medium margins on tablet
      desktop: EdgeInsets.symmetric(horizontal: 200.w), // Large margins on desktop
    );

    final contentPadding = getResponsiveValue(
      mobile: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      tablet: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      desktop: EdgeInsets.symmetric(horizontal: 28.w, vertical: 28.h),
    );

    final bottomSpacing = getResponsiveValue(
      mobile: 40.h,
      tablet: 60.h,
      desktop: 86.h,
    );

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
          margin: containerMargin,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFEBEBEB)),
                  ),
                  margin: contentHorizontalMargin,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: contentPadding,
                      child: Column(
                        children: [
                          // Save button (appears when there are unsaved changes)
                          if (_hasUnsavedChanges) ...[
                            _buildSaveButton(state.isProfileUpdateLoading),
                            SizedBox(height: getResponsiveValue(mobile: 12.h, tablet: 14.h, desktop: 16.h)),
                          ],
                          SettingsAvatarSection(
                            onCameraIconTap: _pickAndUpdateImage,
                            userImage: state.user?.avatar,
                            userName: state.hasUser 
                                ? '${state.user!.firstName} ${state.user!.lastName}'
                                : 'AR',
                          ),
                          SizedBox(height: getResponsiveValue(mobile: 20.h, tablet: 22.h, desktop: 24.h)),
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
              SizedBox(height: bottomSpacing),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final headerPadding = getResponsiveValue(
      mobile: EdgeInsets.only(left: 20.w, top: 16.h),
      tablet: EdgeInsets.only(left: 24.w, top: 18.h),
      desktop: EdgeInsets.only(left: 30.w, top: 20.h),
    );

    final titleFontSize = getResponsiveValue(
      mobile: 20.sp,
      tablet: 24.sp,
      desktop: 28.sp,
    );

    return Container(
      padding: headerPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Settings',
            style: AppTextStyles.p2SemiBold(context).copyWith(
              color: AppColors.black,
              fontSize: titleFontSize,
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
    final buttonFontSize = getResponsiveValue(
      mobile: 12.sp,
      tablet: 13.sp,
      desktop: 14.sp,
    );

    final loaderSize = getResponsiveValue(
      mobile: 14.w,
      tablet: 15.w,
      desktop: 16.w,
    );

    return Align(
      alignment: Alignment.centerRight,
      child: isLoading 
          ? SizedBox(
              width: loaderSize,
              height: loaderSize,
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
                  fontSize: buttonFontSize,
                  color: AppColors.main500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildDivider() {
    final dividerSpacing = getResponsiveValue(
      mobile: EdgeInsets.symmetric(vertical: 20.h),
      tablet: EdgeInsets.symmetric(vertical: 22.h),
      desktop: EdgeInsets.symmetric(vertical: 24.h),
    );

    return Padding(
      padding: dividerSpacing,
      child: Container(height: 1, color: const Color(0xFFEBEBEB)),
    );
  }
}
