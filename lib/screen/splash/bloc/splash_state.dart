part of 'splash_bloc.dart';

@immutable
sealed class SplashState {}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

final class SplashSuccess extends SplashState {
  SplashSuccess(this.appVersion);

  final AppVersion appVersion;
}

final class SplashError extends SplashState {
  SplashError(this.message);

  final String message;
}
