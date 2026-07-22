part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthLoginWithUsernameEvent extends AuthEvent {
  AuthLoginWithUsernameEvent({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

final class AuthLoginWithTokenEvent extends AuthEvent {
  AuthLoginWithTokenEvent({required this.token});

  final String token;
}

final class AuthLoginWithGoogleEvent extends AuthEvent {
  AuthLoginWithGoogleEvent({required this.token});

  final String token;
}

final class AuthSendOtpEvent extends AuthEvent {
  AuthSendOtpEvent({required this.phone});

  final String phone;
}

final class AuthVerifyOtpEvent extends AuthEvent {
  AuthVerifyOtpEvent({
    required this.phone,
    required this.code,
  });

  final String phone;
  final String code;
}

final class AuthDeleteDeviceEvent extends AuthEvent {
  AuthDeleteDeviceEvent({required this.index});

  final int index;
}

final class AuthRegisterEvent extends AuthEvent {
  AuthRegisterEvent({
    required this.email,
    required this.username,
    required this.password,
    this.phone = '',
  });

  final String email;
  final String username;
  final String password;
  final String phone;
}
