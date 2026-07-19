import 'package:bloc/bloc.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/model/app/app_version.dart';
import 'package:bamabin_desktop/data/remote/model/app/startup_data.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/url_repository.dart';
import 'package:bamabin_desktop/repository/video_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:flutter/foundation.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AppRepository appRepository;
  final VideoRepository videoRepository;
  final UrlRepository urlRepository;

  SplashBloc(this.appRepository, this.videoRepository, this.urlRepository)
    : super(SplashInitial()) {
    on<GetStartupData>((event, emit) async {
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
    });
  }
}
