abstract class LoginEvent {}

class RegisterKeyEvent extends LoginEvent {}

class LoginIdChanged extends LoginEvent {
  LoginIdChanged(this.id);
  final String id;
}

class LoginPasswordChanged extends LoginEvent {
  LoginPasswordChanged(this.password);
  final String password;
}

class LoginSubmitted extends LoginEvent {}

class LoginErrorShown extends LoginEvent {}
