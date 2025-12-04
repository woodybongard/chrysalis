part of 'profile_bloc.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.user,
    this.isLoading = false,
    this.isPasswordChangeLoading = false,
    this.isNotificationToggleLoading = false,
    this.isProfileUpdateLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  final ProfileUserEntity? user;
  final bool isLoading;
  final bool isPasswordChangeLoading;
  final bool isNotificationToggleLoading;
  final bool isProfileUpdateLoading;
  final String? errorMessage;
  final String? successMessage;

  bool get hasUser => user != null;
  bool get hasError => errorMessage != null;
  bool get hasSuccess => successMessage != null;

  @override
  List<Object?> get props => [
        user,
        isLoading,
        isPasswordChangeLoading,
        isNotificationToggleLoading,
        isProfileUpdateLoading,
        errorMessage,
        successMessage,
      ];

  ProfileState copyWith({
    ProfileUserEntity? user,
    bool? isLoading,
    bool? isPasswordChangeLoading,
    bool? isNotificationToggleLoading,
    bool? isProfileUpdateLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isPasswordChangeLoading: isPasswordChangeLoading ?? this.isPasswordChangeLoading,
      isNotificationToggleLoading: isNotificationToggleLoading ?? this.isNotificationToggleLoading,
      isProfileUpdateLoading: isProfileUpdateLoading ?? this.isProfileUpdateLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}