import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/api_service/app_api_service.dart';
import 'package:bamabin_desktop/data/remote/api_service/root_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/app/department.dart';
import 'package:bamabin_desktop/data/remote/model/app/gateway.dart';
import 'package:bamabin_desktop/data/remote/model/app/notification.dart';
import 'package:bamabin_desktop/data/remote/model/app/plan.dart';
import 'package:bamabin_desktop/data/remote/model/app/startup_data.dart';
import 'package:bamabin_desktop/data/local/shared_preference_helper.dart';
import 'package:bamabin_desktop/data/remote/url_helper.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRepository {
  final AppApiService _appApiService;
  final RootApiService _rootApiService;
  final SharedPreferenceHelper _sharedPreferenceHelper;

  AppRepository(
    this._appApiService,
    this._rootApiService,
    this._sharedPreferenceHelper,
  );

  Future<DataState<bool>> allowAccess() async {
    bool allowAccess = await _sharedPreferenceHelper.getAllowAccess();
    if (allowAccess) {
      return DataSuccess(true);
    }

    final response = await _rootApiService.getStartupData();
    if (response.status) {
      allowAccess = response.data!.appType == 'main';
      if (allowAccess) {
        await _sharedPreferenceHelper.setAllowAccess(true);
      }
      return DataSuccess(allowAccess);
    } else {
      return DataSuccess(false);
    }
  }

  Future<DataState<StartupData>> getStartupData() async {
    final urlData = _sharedPreferenceHelper.getUrlData();
    if (urlData.isEmpty) {
      return DataError('خطایی رخ داده است');
    }
    UrlHelper.setData(urlData);

    TempDb.apiKey = _sharedPreferenceHelper.getApiKey();
    if (TempDb.apiKey.isNotEmpty) {
      TempDb.username = _sharedPreferenceHelper.getUsername();
      TempDb.avatar = _sharedPreferenceHelper.getAvatar();
      TempDb.isLoggedIn.value = true;
    }

    final response = await _appApiService.getStartupData();
    if (response.status) {
      TempDb.genres = response.data!.genres;
      TempDb.aboutUs = response.data!.aboutUs;
      TempDb.vipInfo.value = response.data!.vipInfo;
      TempDb.haveUnreadNotif.value = response.data!.haveUnreadNotif;
      TempDb.supportLink = response.data!.supportLink;

      if (!response.data!.isAuth) {
        await _sharedPreferenceHelper.clearAuthData();
        TempDb.isLoggedIn.value = false;
        TempDb.apiKey = '';
        TempDb.username = '';
        TempDb.avatar = '';
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      response.data!.version
        ..needUpdate = response.data!.version.version > currentBuild
        ..isRequires = response.data!.version.requiresVersion > currentBuild;

      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Department>>> getDepartments(String type) async {
    final response = await _appApiService.getDepartments(type);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> saveReport(
    int department,
    String content,
    int postId,
  ) async {
    final response = await _appApiService.saveReport(
      department,
      content,
      postId,
    );
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<void>> getSearchTaxonomies() async {
    final response = await _appApiService.getSearchTaxonomies();
    if (response.status) {
      TempDb.contries = response.data!.countries;
      TempDb.languages = response.data!.languages;
      TempDb.ageRates = response.data!.ageRates;
      TempDb.networks = response.data!.networks;
      return DataSuccess(null);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Plan>>> getPlans() async {
    final response = await _appApiService.getPlans();
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Gateway>>> getGateways() async {
    final response = await _appApiService.getGateways();
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<int>> verifyDiscount(int planId, String code) async {
    final response = await _appApiService.verifyDiscount(planId, code);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<String>> buy(int planId, String gateway, String code) async {
    final response = await _appApiService.buy(planId, gateway, code);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<List<Notification>>> getAllNotifications(int page) async {
    final response = await _appApiService.getAllNotifications(page);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<dynamic>> deleteAllNotifications(int id) async {
    final response = await _appApiService.deleteAllNotifications(id);
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<DataState<String>> getTelegramToken() async {
    final response = await _appApiService.getTelegramToken();
    if (response.status) {
      return DataSuccess(response.data);
    } else {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
  }

  Future<void> setSubTextColor(int data) async {
    await _sharedPreferenceHelper.setSubTextColor(data);
  }

  Future<int> getSubTextColor() async {
    return await _sharedPreferenceHelper.getSubTextColor();
  }

  Future<void> setSubBgColor(int data) async {
    await _sharedPreferenceHelper.setSubBgColor(data);
  }

  Future<int> getSubBgColor() async {
    return await _sharedPreferenceHelper.getSubBgColor();
  }

  Future<void> setSubFont(int data) async {
    await _sharedPreferenceHelper.setSubFont(data);
  }

  Future<int> getSubFont() async {
    return await _sharedPreferenceHelper.getSubFont();
  }

  Future<void> setSubSize(int data) async {
    await _sharedPreferenceHelper.setSubSize(data);
  }

  Future<int> getSubSize() async {
    return await _sharedPreferenceHelper.getSubSize();
  }

  Future<void> setSubMargin(int data) async {
    await _sharedPreferenceHelper.setSubMargin(data);
  }

  Future<int> getSubMargin() async {
    return await _sharedPreferenceHelper.getSubMargin();
  }

  Future<void> setVideoSpeed(int data) async {
    await _sharedPreferenceHelper.setVideoSpeed(data);
  }

  Future<int> getVideoSpeed() async {
    return await _sharedPreferenceHelper.getVideoSpeed();
  }
}
