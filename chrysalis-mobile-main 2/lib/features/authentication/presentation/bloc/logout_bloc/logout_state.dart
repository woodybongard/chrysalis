part of 'logout_bloc.dart';

abstract class LogoutState {}

class LogoutInitial extends LogoutState {}

class LogoutInProgress extends LogoutState {}

class LogoutSuccess extends LogoutState {}

class LogoutFailure extends LogoutState {
  LogoutFailure(this.message);
  final String message;
}
