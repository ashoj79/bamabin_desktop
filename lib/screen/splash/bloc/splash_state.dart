part of 'splash_bloc.dart';

@immutable
sealed class SplashState {}

final class SplashInitial extends SplashState {}

final class SplashLoading extends SplashState {}

@immutable
sealed class UpdateDownloadState {
  const UpdateDownloadState();
}

final class UpdateDownloadIdle extends UpdateDownloadState {
  const UpdateDownloadIdle();
}

final class UpdateDownloadDownloading extends UpdateDownloadState {
  const UpdateDownloadDownloading({
    required this.downloadedBytes,
    required this.totalBytes,
  });

  final int downloadedBytes;
  final int totalBytes;

  int get percent {
    if (totalBytes <= 0) return 0;
    return ((downloadedBytes * 100) ~/ totalBytes).clamp(0, 100);
  }
}

final class UpdateDownloadReady extends UpdateDownloadState {
  const UpdateDownloadReady(this.filePath);

  final String filePath;
}

final class UpdateDownloadError extends UpdateDownloadState {
  const UpdateDownloadError(this.message);

  final String message;
}

final class SplashSuccess extends SplashState {
  SplashSuccess(
    this.appVersion, {
    this.downloadState = const UpdateDownloadIdle(),
  });

  final AppVersion appVersion;
  final UpdateDownloadState downloadState;

  SplashSuccess copyWith({
    AppVersion? appVersion,
    UpdateDownloadState? downloadState,
  }) {
    return SplashSuccess(
      appVersion ?? this.appVersion,
      downloadState: downloadState ?? this.downloadState,
    );
  }
}

final class SplashError extends SplashState {
  SplashError(this.message);

  final String message;
}
