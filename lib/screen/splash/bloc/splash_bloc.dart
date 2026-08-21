import 'package:bloc/bloc.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/app_version.dart';
import 'package:bamabin_desktop/data/remote/model/app/startup_data.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/url_repository.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AppRepository appRepository;
  final VideoRepository videoRepository;
  final UrlRepository urlRepository;

  CancelToken? _updateCancelToken;

  SplashBloc(this.appRepository, this.videoRepository, this.urlRepository)
    : super(SplashInitial()) {
    appRepository.cleanupLeftoverUpdates();

    on<GetStartupData>(_onGetStartupData);
    on<StartAppUpdateDownload>(_onStartAppUpdateDownload);
    on<AppUpdateDownloadProgress>(_onAppUpdateDownloadProgress);
    on<ResetAppUpdateDownload>(_onResetAppUpdateDownload);
  }

  Future<void> _onGetStartupData(
    GetStartupData event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashLoading());
    var result = await appRepository.getStartupData();
    if (result is DataError) {
      final urlResult = await urlRepository.getBaseUrl();
      if (urlResult is DataError) {
        emit(SplashError(urlResult.errorMessage));
        return;
      }

      result = await appRepository.getStartupData();
      if (result is DataError) {
        emit(SplashError(result.errorMessage));
        return;
      }
    }

    if (TempDb.isLoggedIn.value) {
      final departmentsResult = await appRepository.getDepartments('report');
      if (departmentsResult is DataError) {
        emit(SplashError(departmentsResult.errorMessage));
        return;
      }
      TempDb.departments = departmentsResult.data!;
    }

    final videoResult = await videoRepository.getHomeSections();
    if (videoResult is DataError) {
      emit(SplashError(videoResult.errorMessage));
      return;
    }

    final searchTaxonomiesResult = await appRepository.getSearchTaxonomies();
    if (searchTaxonomiesResult is DataError) {
      emit(SplashError(searchTaxonomiesResult.errorMessage));
      return;
    }

    final appVersion = (result as DataSuccess<StartupData>).data!.version;

    emit(SplashSuccess(appVersion));
  }

  Future<void> _onStartAppUpdateDownload(
    StartAppUpdateDownload event,
    Emitter<SplashState> emit,
  ) async {
    final current = state;
    if (current is! SplashSuccess) return;
    if (current.downloadState is UpdateDownloadDownloading) return;

    final url = current.appVersion.directLink.trim();
    if (url.isEmpty) {
      emit(
        current.copyWith(
          downloadState: const UpdateDownloadError('لینک دانلود معتبر نیست'),
        ),
      );
      return;
    }

    _updateCancelToken?.cancel();
    _updateCancelToken = CancelToken();

    emit(
      current.copyWith(
        downloadState: const UpdateDownloadDownloading(
          downloadedBytes: 0,
          totalBytes: 0,
        ),
      ),
    );

    try {
      final file = await appRepository.downloadAppUpdate(
        url: url,
        cancelToken: _updateCancelToken,
        onProgress: (downloaded, total) {
          add(
            AppUpdateDownloadProgress(
              downloadedBytes: downloaded,
              totalBytes: total,
            ),
          );
        },
      );

      if (emit.isDone) return;
      final latest = state;
      if (latest is! SplashSuccess) return;

      emit(
        latest.copyWith(downloadState: UpdateDownloadReady(file.path)),
      );
    } catch (e) {
      await appRepository.cleanupLeftoverUpdates();
      if (emit.isDone) return;
      final latest = state;
      if (latest is! SplashSuccess) return;

      final message = e is DioException && e.type == DioExceptionType.cancel
          ? ''
          : (e is DioException
                ? (e.message?.trim().isNotEmpty == true
                      ? e.message!
                      : 'دانلود با خطا مواجه شد')
                : 'دانلود با خطا مواجه شد');

      if (message.isEmpty) {
        emit(latest.copyWith(downloadState: const UpdateDownloadIdle()));
        return;
      }

      emit(latest.copyWith(downloadState: UpdateDownloadError(message)));
    } finally {
      _updateCancelToken = null;
    }
  }

  void _onAppUpdateDownloadProgress(
    AppUpdateDownloadProgress event,
    Emitter<SplashState> emit,
  ) {
    final current = state;
    if (current is! SplashSuccess) return;
    if (current.downloadState is! UpdateDownloadDownloading &&
        current.downloadState is! UpdateDownloadIdle) {
      return;
    }

    emit(
      current.copyWith(
        downloadState: UpdateDownloadDownloading(
          downloadedBytes: event.downloadedBytes,
          totalBytes: event.totalBytes,
        ),
      ),
    );
  }

  Future<void> _onResetAppUpdateDownload(
    ResetAppUpdateDownload event,
    Emitter<SplashState> emit,
  ) async {
    _updateCancelToken?.cancel();
    _updateCancelToken = null;
    await appRepository.cleanupLeftoverUpdates();

    final current = state;
    if (current is! SplashSuccess) return;
    emit(current.copyWith(downloadState: const UpdateDownloadIdle()));
  }

  Future<void> openInstallerAndExit(String filePath) {
    return appRepository.openInstallerAndExit(filePath);
  }
}
