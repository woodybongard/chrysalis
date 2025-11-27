import 'dart:io';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/contact_admin_utils.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/widgets/loading_indicator.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/logout_bloc/logout_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/custom_profile_menu_item.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/notification_preferences_section.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_app_bar.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_logout_button.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_user_info.dart';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProfileBloc>().add(const LoadUserProfileEvent()));
  }

  void _contactAdmin() => ContactAdminUtils.launchContactAdmin(context);

  void _showImagePicker() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final scaleHeight = context.scaleHeight;
        return Container(
          padding: EdgeInsets.all(context.scaleWidth * 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Image',
                style: AppTextStyles.headlineMedium(context),
              ),
              SizedBox(height: scaleHeight * 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryMain),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryMain),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              SizedBox(height: scaleHeight * 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        // Update profile with new image
        context.read<ProfileBloc>().add(
          UpdateProfileImageEvent(File(image.path)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: \$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return MultiBlocListener(
      listeners: [
        BlocListener<LogoutBloc, LogoutState>(
          listener: (context, state) {
            if (state is LogoutInProgress) {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
            } else if (state is LogoutSuccess) {
              Navigator.of(context).pop();
              context.go('/');
            } else if (state is LogoutFailure) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.isLoading && !state.hasUser) {
              return const Center(child: LoadingIndicator());
            }

            if (state.hasError && !state.hasUser) {
              return _buildErrorState(context, state, scaleHeight, scaleWidth);
            }

            if (state.hasUser) {
              return _buildProfileContent(context, state, scaleHeight, scaleWidth);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ProfileState state, double scaleHeight, double scaleWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64 * scaleWidth, color: AppColors.neural400),
          SizedBox(height: scaleHeight * 16),
          Text('Failed to load profile', style: AppTextStyles.p1bold(context).copyWith(color: AppColors.neural502)),
          SizedBox(height: scaleHeight * 8),
          Text(state.errorMessage!, style: AppTextStyles.captionRegular(context).copyWith(color: AppColors.neural400), textAlign: TextAlign.center),
          SizedBox(height: scaleHeight * 24),
          ElevatedButton(
            onPressed: () => context.read<ProfileBloc>().add(const LoadUserProfileEvent()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryMain, foregroundColor: AppColors.white),
            child: Text('Retry', style: AppTextStyles.p2SemiBold(context).copyWith(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ProfileState state, double scaleHeight, double scaleWidth) {
    return SafeArea(
      child: Column(
        children: [
          const ProfileAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
              child: Column(
                children: [
                  SizedBox(height: 24 * scaleHeight),
                  ProfileUserInfo(
                    displayName: state.user!.displayName,
                    username: state.user!.username,
                    avatarUrl: state.user!.avatar,
                    initials: state.user!.initials,
                    onCameraTap: _showImagePicker,
                  ),
                  SizedBox(height: 24 * scaleHeight),
                  CustomProfileMenuItem(iconPath: Assets.iconsIcPassword, title: 'Change password', onTap: () => context.goNamed(AppRoutes.changePassword)),
                  SizedBox(height: 24 * scaleHeight),
                  CustomProfileMenuItem(iconPath: Assets.iconsIcContactAdmin, title: 'Contact admin', onTap: _contactAdmin),
                  SizedBox(height: 24 * scaleHeight),
                  NotificationPreferencesSection(
                    isPushNotificationEnabled: state.user!.isNotification,
                    onPushNotificationToggle: () => context.read<ProfileBloc>().add(ToggleNotificationsEvent(!state.user!.isNotification)),
                  ),
                  SizedBox(height: 24 * scaleHeight),
                  ProfileLogoutButton(onTap: () => context.read<LogoutBloc>().add(LogoutRequested())),
                  SizedBox(height: 32 * scaleHeight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
