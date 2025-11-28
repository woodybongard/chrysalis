import 'package:chrysalis_mobile/features/profile/domain/entity/profile_user_entity.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/change_password_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/get_user_profile_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/toggle_notifications_usecase.dart';
import 'package:chrysalis_mobile/features/profile/domain/usecase/update_profile_usecase.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(
    this.getUserProfileUseCase,
    this.changePasswordUsecase,
    this.toggleNotificationsUsecase,
    this.updateProfileUsecase,
  ) : super(const ProfileState()) {
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ToggleNotificationsEvent>(_onToggleNotifications);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateProfileImageEvent>(_onUpdateProfileImage);
    on<UpdateProfileImageWebEvent>(_onUpdateProfileImageWeb);
  }

  final GetUserProfileUseCase getUserProfileUseCase;
  final ChangePasswordUsecase changePasswordUsecase;
  final ToggleNotificationsUsecase toggleNotificationsUsecase;
  final UpdateProfileUsecase updateProfileUsecase;

  Future<void> _onLoadUserProfile(
    LoadUserProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final response = await getUserProfileUseCase();
      emit(state.copyWith(
        user: response.user,
        isLoading: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.user == null) return;

    emit(state.copyWith(
      isPasswordChangeLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await changePasswordUsecase(
        state.user!.id,
        event.currentPassword,
        event.newPassword,
      );
      emit(state.copyWith(
        isPasswordChangeLoading: false,
        successMessage: message,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isPasswordChangeLoading: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onToggleNotifications(
    ToggleNotificationsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.user == null) return;

    // Optimistically update UI first
    final updatedUser = ProfileUserEntity(
      id: state.user!.id,
      email: state.user!.email,
      username: state.user!.username,
      firstName: state.user!.firstName,
      lastName: state.user!.lastName,
      avatar: state.user!.avatar,
      role: state.user!.role,
      isActive: state.user!.isActive,
      isVerified: state.user!.isVerified,
      isNotification: event.isNotification,
      lastLogin: state.user!.lastLogin,
      createdAt: state.user!.createdAt,
      updatedAt: state.user!.updatedAt,
    );

    emit(state.copyWith(
      user: updatedUser,
      isNotificationToggleLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      final message = await toggleNotificationsUsecase(event.isNotification);
      emit(state.copyWith(
        isNotificationToggleLoading: false,
        successMessage: message,
        clearError: true,
      ));
    } catch (e) {
      // Revert to previous state on error
      emit(state.copyWith(
        user: state.user,
        isNotificationToggleLoading: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.user == null) return;

    emit(state.copyWith(
      isProfileUpdateLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      await updateProfileUsecase(
        firstName: event.firstName,
        lastName: event.lastName,
        username: event.username,
        image: event.image,
        imageFile: event.imageFile,
      );

      // Create updated user with new data
      final updatedUser = ProfileUserEntity(
        id: state.user!.id,
        email: state.user!.email,
        username: event.username,
        firstName: event.firstName,
        lastName: event.lastName,
        avatar: (event.image != null || event.imageFile != null) ? null : state.user!.avatar, // Will be updated by server
        role: state.user!.role,
        isActive: state.user!.isActive,
        isVerified: state.user!.isVerified,
        isNotification: state.user!.isNotification,
        lastLogin: state.user!.lastLogin,
        createdAt: state.user!.createdAt,
        updatedAt: state.user!.updatedAt,
      );

      emit(state.copyWith(
        user: updatedUser,
        isProfileUpdateLoading: false,
        successMessage: 'Profile updated successfully',
        clearError: true,
      ));

      // Clear success message after a short delay to prevent multiple triggers
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearSuccess: true));
        }
      });

      // Reload profile to get updated avatar URL from server
      add(const LoadUserProfileEvent());
    } catch (e) {
      emit(state.copyWith(
        isProfileUpdateLoading: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      ));

      // Clear error message after a short delay
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearError: true));
        }
      });
    }
  }

  Future<void> _onUpdateProfileImage(
    UpdateProfileImageEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.user == null) return;

    debugPrint('🔄 ProfileBloc: Starting profile image update');
    debugPrint('📂 Image path: ${event.image.path}');
    debugPrint('📂 Image name: ${event.image.name}');

    emit(state.copyWith(
      isProfileUpdateLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      debugPrint('📤 ProfileBloc: Calling updateProfileUsecase');
      await updateProfileUsecase(
        firstName: state.user!.firstName,
        lastName: state.user!.lastName,
        username: state.user!.username,
        imageFile: event.image,
      );
      debugPrint('✅ ProfileBloc: Profile image update successful');

      emit(state.copyWith(
        isProfileUpdateLoading: false,
        successMessage: 'Profile image updated successfully',
        clearError: true,
      ));

      // Clear success message after a short delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearSuccess: true));
        }
      });

      // Reload profile to get updated avatar URL from server
      add(const LoadUserProfileEvent());
    } catch (e) {
      emit(state.copyWith(
        isProfileUpdateLoading: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      ));

      // Clear error message after a short delay
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearError: true));
        }
      });
    }
  }

  Future<void> _onUpdateProfileImageWeb(
    UpdateProfileImageWebEvent event,
    Emitter<ProfileState> emit,
  ) async {
    if (state.user == null) return;

    debugPrint('🎯 ProfileBloc: *** WEB EVENT RECEIVED *** UpdateProfileImageWebEvent');
    debugPrint('🌐 ProfileBloc: Starting web profile image update');
    debugPrint('👤 User ID: ${state.user!.id}');
    debugPrint('👤 First Name: ${state.user!.firstName}');
    debugPrint('👤 Last Name: ${state.user!.lastName}');
    debugPrint('👤 Username: ${state.user!.username}');
    debugPrint('📂 File name: ${event.fileName}');
    debugPrint('📂 MIME type: ${event.mimeType}');
    debugPrint('📂 File size: ${event.imageBytes.length} bytes');

    emit(state.copyWith(
      isProfileUpdateLoading: true,
      clearError: true,
      clearSuccess: true,
    ));

    try {
      debugPrint('📤 ProfileBloc: Calling updateProfileWebUsecase');
      await updateProfileUsecase.callWeb(
        firstName: state.user!.firstName,
        lastName: state.user!.lastName,
        username: state.user!.username,
        imageBytes: event.imageBytes,
        fileName: event.fileName,
        mimeType: event.mimeType,
      );
      debugPrint('✅ ProfileBloc: Web profile image update successful');

      emit(state.copyWith(
        isProfileUpdateLoading: false,
        successMessage: 'Profile image updated successfully',
        clearError: true,
      ));

      // Clear success message after a short delay
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearSuccess: true));
        }
      });

      // Reload profile to get updated avatar URL from server
      add(const LoadUserProfileEvent());
    } catch (e) {
      debugPrint('❌ ProfileBloc: Web profile image update failed - $e');
      emit(state.copyWith(
        isProfileUpdateLoading: false,
        errorMessage: e.toString(),
        clearSuccess: true,
      ));

      // Clear error message after a short delay
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (!emit.isDone) {
          emit(state.copyWith(clearError: true));
        }
      });
    }
  }
}