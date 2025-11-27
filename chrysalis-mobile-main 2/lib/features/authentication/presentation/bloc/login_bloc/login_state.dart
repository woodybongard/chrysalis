import 'package:chrysalis_mobile/features/authentication/domain/entity/login_response_entity.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {
  LoginInitial({this.id = '', this.password = '', this.isValid = false});
  final String id;
  final String password;
  final bool isValid;
}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  LoginSuccess(this.response);
  final LoginResponseEntity response;
}

class RegisterKeySuccess extends LoginState {}

class LoginError extends LoginState {
  LoginError(this.message);
  final String message;
}
