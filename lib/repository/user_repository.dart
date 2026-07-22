import 'dart:io';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/data/remote/api_service/user_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/user/auth_response.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:bamabin_desktop/data/remote/model/user/request.dart';
import 'package:bamabin_desktop/data/remote/model/user/user_list.dart';
import 'package:bamabin_desktop/data/remote/model/user/vip_info.dart';
import 'package:bamabin_desktop/data/remote/model/user/watch_report.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/watch_status_posts.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:bamabin_desktop/data/local/shared_preference_helper.dart';
import 'package:bamabin_desktop/data/local/database/watch_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_episode_dao.dart';
import 'package:bamabin_desktop/data/local/database/watched_movie_dao.dart';
import 'package:bamabin_desktop/data/local/database/watching_episode_dao.dart';
import 'package:dio/dio.dart';

class UserRepository {
  final UserApiService _userApiService;
  final SharedPreferenceHelper _sharedPreferenceHelper;
  final WatchDao _watchDao;
  final WatchedEpisodeDao _watchedEpisodeDao;
  final WatchedMovieDao _watchedMovieDao;
  final WatchingEpisodeDao _watchingEpisodeDao;

  UserRepository(
    this._userApiService,
    this._sharedPreferenceHelper,
    this._watchDao,
    this._watchedEpisodeDao,
    this._watchedMovieDao,
    this._watchingEpisodeDao,
  );

  String getEmail() {
    return _sharedPreferenceHelper.getEmail();
  }

  String getFirstName() {
    return _sharedPreferenceHelper.getFirstName();
  }

  String getLastName() {
    return _sharedPreferenceHelper.getLastName();
  }

  String getNickname() {
    return _sharedPreferenceHelper.getNickname();
  }

  String getPhone() {
    return _sharedPreferenceHelper.getPhone();
  }

  String getCity() {
    return _sharedPreferenceHelper.getCity();
  }

  String getDescription() {
    return _sharedPreferenceHelper.getDescription();
  }

  String getUsername() {
    return _sharedPreferenceHelper.getUsername();
  }

  String getAvatar() {
    return _sharedPreferenceHelper.getAvatar();
  }

  Future<DataState<AuthResponse>> loginWithUsername(
    String username,
    String password,
  ) async {
    Map<String, String> deviceInfo = await _getDeviceInfo();
    final response = await _userApiService.login(
      username,
      password,
      deviceInfo['device_model']!,
      deviceInfo['system_version']!,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }

    TempDb.apiKey = response.data!.apiKey;
    if (response.data!.deviceLimit) {
      return DataError('device_limit');
    }
    await _sharedPreferenceHelper.setApiKey(response.data!.apiKey);

    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    TempDb.isLoggedIn.value = true;
    return DataSuccess(response.data);
  }

  Future<DataState<AuthResponse>> loginWithToken(String token) async {
    Map<String, String> deviceInfo = await _getDeviceInfo();
    final response = await _userApiService.easyLogin(
      token,
      deviceInfo['device_model']!,
      deviceInfo['system_version']!,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }

    TempDb.apiKey = response.data!.apiKey;
    if (response.data!.deviceLimit) {
      return DataError('device_limit');
    }
    await _sharedPreferenceHelper.setApiKey(response.data!.apiKey);

    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    TempDb.isLoggedIn.value = true;
    return DataSuccess(response.data);
  }

  Future<DataState<void>> loginWithApiKey(String apiKey) async {
    TempDb.apiKey = apiKey;
    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    await _sharedPreferenceHelper.setApiKey(apiKey);
    TempDb.isLoggedIn.value = true;
    return DataSuccess();
  }

  Future<DataState<AuthResponse>> loginWithGoogle(String token) async {
    Map<String, String> deviceInfo = await _getDeviceInfo();
    final response = await _userApiService.loginWithGoogle(
      token,
      deviceInfo['device_model']!,
      deviceInfo['system_version']!,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }

    TempDb.apiKey = response.data!.apiKey;
    if (response.data!.deviceLimit) {
      return DataError('device_limit');
    }
    await _sharedPreferenceHelper.setApiKey(response.data!.apiKey);

    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    TempDb.isLoggedIn.value = true;
    return DataSuccess(response.data);
  }

  Future<DataState<void>> sendOtp(String phone) async {
    final response = await _userApiService.sendOtp(phone);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(null);
  }

  Future<DataState<AuthResponse>> verifyOtp(String phone, String code) async {
    Map<String, String> deviceInfo = await _getDeviceInfo();
    final response = await _userApiService.verifyOtp(
      phone,
      code,
      deviceInfo['device_model']!,
      deviceInfo['system_version']!,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }

    TempDb.apiKey = response.data!.apiKey;
    if (response.data!.deviceLimit) {
      return DataError('device_limit');
    }
    await _sharedPreferenceHelper.setApiKey(response.data!.apiKey);

    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    TempDb.isLoggedIn.value = true;
    return DataSuccess(response.data);
  }

  Future<DataState<AuthResponse>> tvRemoteLogin(String token) async {
    final response = await _userApiService.tvRemoteLogin(token);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }

    if (response.data!.deviceLimit) {
      return DataError('device_limit');
    }

    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> register(
    String email,
    String username,
    String password,
    String passwordSubmit, {
    String phone = '',
  }) async {
    Map<String, String> deviceInfo = await _getDeviceInfo();
    final response = await _userApiService.register(
      email,
      username,
      password,
      passwordSubmit,
      deviceInfo['device_model']!,
      deviceInfo['system_version']!,
      phone: phone,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    TempDb.apiKey = response.data!;
    await _sharedPreferenceHelper.setApiKey(response.data!);
    if (!(await _getUserData())) {
      return DataError('خطایی رخ داده است');
    }
    TempDb.isLoggedIn.value = true;

    return DataSuccess(response.data);
  }

  Future<DataState<void>> sendResetPasswordEmail(String email) async {
    final response = await _userApiService.forgotPassword(email);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(null, response.message ?? 'خطایی رخ داده است');
  }

  Future<DataState<List<Device>>> getDevices() async {
    final response = await _userApiService.getDevices();
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> deleteDevice(int id) async {
    final response = await _userApiService.deleteDevice(id);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    if (id == -1) {
      await _clearLocalSession();
    }
    return DataSuccess(response.data);
  }

  Future<DataState<WatchReport>> getWatchReport() async {
    final response = await _userApiService.getWatchReport();
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<WatchStatusPosts>> getAllWatchStatusPosts() async {
    final response = await _userApiService.getAllWatchStatusPosts();
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> editProfile(
    String firstName,
    String lastName,
    String nickname,
    String email,
    String city,
    String phone,
    String description,
  ) async {
    final response = await _userApiService.editProfile(
      firstName,
      lastName,
      nickname,
      email,
      city,
      phone,
      description,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    await _sharedPreferenceHelper.setFirstName(firstName);
    await _sharedPreferenceHelper.setLastName(lastName);
    await _sharedPreferenceHelper.setNickname(nickname);
    await _sharedPreferenceHelper.setEmail(email);
    await _sharedPreferenceHelper.setCity(city);
    await _sharedPreferenceHelper.setPhone(phone);
    await _sharedPreferenceHelper.setDescription(description);
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> updatePassword(
    String currentPassword,
    String password,
    String passwordSubmit,
  ) async {
    final response = await _userApiService.updatePassword(
      currentPassword,
      password,
      passwordSubmit,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> updateAvatar(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return DataError('فایل تصویر معتبر نیست');
      }

      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'avatar.jpg';
      final multipartFile = await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      );

      final response = await _userApiService.updateAvatar(multipartFile);
      if (!response.status) {
        return DataError(response.message ?? 'خطایی رخ داده است');
      }

      final avatarUrl = response.data;
      if (avatarUrl != null && avatarUrl.isNotEmpty) {
        TempDb.avatar = avatarUrl;
        await _sharedPreferenceHelper.setAvatar(avatarUrl);
      } else {
        await _getUserData();
      }

      return DataSuccess('');
    } catch (_) {
      return DataError('مشکلی پیش آمد لطفا مجدد امتحان کنید\nError Code: 41');
    }
  }

  Future<DataState<List<Request>>> getRequests() async {
    final response = await _userApiService.getRequests();
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> sendRequest(
    String title,
    String release,
    String type,
  ) async {
    final response = await _userApiService.sendRequest(title, release, type);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<List<UserList>>> getUserLists(int page) async {
    final response = await _userApiService.getUserLists(page);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> createList(String title, String content) async {
    final response = await _userApiService.createList(title, content);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> deleteList(int id) async {
    final response = await _userApiService.deleteList(id);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> editList(
    int id,
    String title,
    String content,
  ) async {
    final response = await _userApiService.editList(id, title, content);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> addToList(int id, int postId) async {
    final response = await _userApiService.addToList(id, postId);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> removeFromList(int id, int postId) async {
    final response = await _userApiService.removeFromList(id, postId);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<void> logout(bool clearToken) async {
    await _userApiService.logout();
    await _clearLocalSession();
  }

  Future<void> _clearLocalSession() async {
    await _watchedEpisodeDao.deleteAll();
    await _watchDao.deleteAll();
    await _watchingEpisodeDao.deleteAll();
    await _watchedMovieDao.deleteAll();
    await _sharedPreferenceHelper.clearAuthData();
    TempDb.isLoggedIn.value = false;
    TempDb.vipInfo.value = VipInfo(isVip: false, days: 0);
  }

  Future<DataState<List<Post>>> getWatchStatusPosts(
    String status,
    int page,
  ) async {
    final response = await _userApiService.getWatchStatusPosts(status, page);
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<DataState<dynamic>> deleteWatchStatusPost(
    String status,
    int postId,
  ) async {
    final response = await _userApiService.deleteWatchStatusPost(
      status,
      postId,
    );
    if (!response.status) {
      return DataError(response.message ?? 'خطایی رخ داده است');
    }
    return DataSuccess(response.data);
  }

  Future<bool> _getUserData() async {
    final response = await _userApiService.getUserData();
    if (!response.status) {
      return false;
    }

    TempDb.vipInfo.value = response.data!.vipInfo!;
    TempDb.username = response.data!.username;
    TempDb.avatar = response.data!.avatar;
    await _sharedPreferenceHelper.setUsername(response.data!.username);
    await _sharedPreferenceHelper.setAvatar(response.data!.avatar);
    await _sharedPreferenceHelper.setEmail(response.data!.email);
    await _sharedPreferenceHelper.setFirstName(response.data!.firstName);
    await _sharedPreferenceHelper.setLastName(response.data!.lastName);
    await _sharedPreferenceHelper.setNickname(response.data!.nickname);
    await _sharedPreferenceHelper.setPhone(response.data!.phone);
    await _sharedPreferenceHelper.setCity(response.data!.city);
    await _sharedPreferenceHelper.setDescription(response.data!.description);

    return true;
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceModel = '';
    String systemVersion = '';

    if (Platform.isLinux) {
      LinuxDeviceInfo linuxInfo = await DeviceInfoPlugin().linuxInfo;
      deviceModel = linuxInfo.name;
      systemVersion = '1.0.0';
    } else if (Platform.isWindows) {
      deviceModel = 'Windows';
      systemVersion = '1.0.0';
    } else if (Platform.isMacOS) {
      deviceModel = 'MacOS';
      systemVersion = '1.0.0';
    }

    return {'device_model': deviceModel, 'system_version': systemVersion};
  }
}
