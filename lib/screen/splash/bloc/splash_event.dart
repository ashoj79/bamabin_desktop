part of 'splash_bloc.dart';

@immutable
sealed class SplashEvent {}

final class GetStartupData extends SplashEvent {}

final class StartAppUpdateDownload extends SplashEvent {}

final class AppUpdateDownloadProgress extends SplashEvent {
  AppUpdateDownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final int downloadedBytes;
  final int totalBytes;
}

final class ResetAppUpdateDownload extends SplashEvent {}
