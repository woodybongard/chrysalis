import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class ProfileAvatarButton extends StatefulWidget {

  const ProfileAvatarButton({
    super.key,
    this.size = 32,
    this.enableNavigation = true,
  });


  final double size;
  final bool enableNavigation;

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  @override
  void initState() {
    super.initState();
    // Load profile data when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = context.read<ProfileBloc>().state;
      if (!profileState.hasUser && !profileState.isLoading) {
        context.read<ProfileBloc>().add(const LoadUserProfileEvent());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enableNavigation 
        ? () {
            if(!kIsWeb){
              context.goNamed(AppRoutes.profile);
            }
          }
        : null,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.isLoading) {
            return Shimmer.fromColors(
              baseColor: AppColors.neural50,
              highlightColor: AppColors.white,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: const BoxDecoration(
                  color: AppColors.neural50,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          
          if (state.hasUser) {
            return ProfileAvatar(
              imageUrl: state.user!.avatar,
              initials: state.user!.initials,
              size: widget.size,
            );
          }
          
          // Default fallback icon
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              color: AppColors.neural50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.neural502,
              size: widget.size * 0.625, // Icon is 62.5% of container size
            ),
          );
        },
      ),
    );
  }
}