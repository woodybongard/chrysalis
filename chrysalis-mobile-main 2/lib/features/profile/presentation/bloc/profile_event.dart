import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfileEvent extends ProfileEvent {
  const LoadUserProfileEvent();
}

class ChangePasswordEvent extends ProfileEvent {
  const ChangePasswordEvent(this.currentPassword, this.newPassword);
  
  final String currentPassword;
  final String newPassword;
  
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

class ToggleNotificationsEvent extends ProfileEvent {
  const ToggleNotificationsEvent(this.isNotification);
  
  final bool isNotification;
  
  @override
  List<Object?> get props => [isNotification];
}

class UpdateProfileEvent extends ProfileEvent {
  const UpdateProfileEvent({
    required this.firstName,
    required this.lastName,
    required this.username,
    this.image,
    this.imageFile,
  });
  
  final String firstName;
  final String lastName;
  final String username;
  final File? image;
  final XFile? imageFile;
  
  @override
  List<Object?> get props => [firstName, lastName, username, image, imageFile];
}

class UpdateProfileImageEvent extends ProfileEvent {
  const UpdateProfileImageEvent(this.image);
  
  final File image;
  
  @override
  List<Object?> get props => [image];
}