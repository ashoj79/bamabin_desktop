part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class AuthLoading extends AuthState {}

final class AuthSuccess extends AuthState {}

final class AuthError extends AuthState {
  AuthError(this.message);

  final String message;
}

final class AuthOtpSent extends AuthState {
  AuthOtpSent(this.phone);

  final String phone;
}

final class AuthDeviceLimit extends AuthState {
  AuthDeviceLimit(this.devices);

  final List<Device> devices;
}

final class AuthDeviceDeleted extends AuthState {}
