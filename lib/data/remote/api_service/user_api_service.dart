import 'package:bamabin_desktop/data/remote/api_service/base_api_service.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';
import 'package:bamabin_desktop/data/remote/model/user/auth_response.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:bamabin_desktop/data/remote/model/user/request.dart';
import 'package:bamabin_desktop/data/remote/model/user/user_data.dart';
import 'package:bamabin_desktop/data/remote/model/user/user_list.dart';
import 'package:bamabin_desktop/data/remote/model/user/watch_report.dart';
import 'package:bamabin_desktop/data/remote/model/videos/post.dart';
import 'package:bamabin_desktop/data/remote/model/videos/watch_status_posts.dart';
import 'package:dio/dio.dart';

class UserApiService extends BaseApiService {
  UserApiService(super.dioHelper);

  Future<ApiResponse<AuthResponse>> login(
    String username,
    String password,
    String deviceModel,
    String systemVersion,
  ) async {
    return await post(
      '/login',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      data: {
        'username': username,
        'password': password,
        'device_model': deviceModel,
        'android_version': systemVersion,
      },
    );
  }

  Future<ApiResponse<AuthResponse>> easyLogin(
    String token,
    String deviceModel,
    String systemVersion,
  ) async {
    return await post(
      '/easy-login',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      data: {
        'token': token,
        'device_model': deviceModel,
        'android_version': systemVersion,
      },
    );
  }

  Future<ApiResponse<AuthResponse>> tvRemoteLogin(String token) async {
    return await post(
      '/tv-remote-login',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      data: {'token': token},
    );
  }

  Future<ApiResponse<AuthResponse>> loginWithGoogle(
    String token,
    String deviceModel,
    String systemVersion,
  ) async {
    return await post(
      '/login-google',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      data: {
        'token': token,
        'device_model': deviceModel,
        'android_version': systemVersion,
      },
    );
  }

  Future<ApiResponse<dynamic>> sendOtp(String phone) async {
    return await post('/send-otp', (json) => null, data: {'phone': phone});
  }

  Future<ApiResponse<AuthResponse>> verifyOtp(
    String phone,
    String code,
    String deviceModel,
    String systemVersion,
  ) async {
    return await post(
      '/verify-otp',
      (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      data: {
        'phone': phone,
        'code': code,
        'device_model': deviceModel,
        'android_version': systemVersion,
      },
    );
  }

  Future<ApiResponse<String>> register(
    String email,
    String username,
    String password,
    String passwordSubmit,
    String deviceModel,
    String systemVersion, {
    String phone = '',
  }) async {
    return await post(
      '/register',
      (json) => json['api_key'],
      data: {
        'email': email,
        'username': username,
        'password': password,
        're_password': passwordSubmit,
        'device_model': deviceModel,
        'android_version': systemVersion,
        if (phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  Future<ApiResponse<UserData>> getUserData() async {
    return await get(
      '/user/data',
      (json) => UserData.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<Device>>> getDevices() async {
    return await get(
      '/devices',
      (json) => List<Device>.generate(
        json.length,
        (index) => Device.fromJson(json[index] as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<dynamic>> deleteDevice(int id) async {
    return await delete(
      '/devices/$id',
      (json) => null,
      data: {'_method': 'delete'},
    );
  }

  Future<ApiResponse<dynamic>> forgotPassword(String email) async {
    return await post('/forget', (json) => null, data: {'email': email});
  }

  Future<ApiResponse<WatchReport>> getWatchReport() async {
    return await get(
      '/watch_report',
      (json) => WatchReport.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<WatchStatusPosts>> getAllWatchStatusPosts() async {
    return await get(
      '/watch_status_posts/all',
      (json) => WatchStatusPosts.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> editProfile(
    String firstName,
    String lastName,
    String nickname,
    String email,
    String city,
    String phone,
    String description,
  ) async {
    return await post(
      '/user/update_profile',
      (json) => null,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'email': email,
        'city': city,
        'phone': phone,
        'description': description,
      },
    );
  }

  Future<ApiResponse<dynamic>> updatePassword(
    String currentPassword,
    String password,
    String passwordSubmit,
  ) async {
    return await post(
      '/user/update_password',
      (json) => null,
      data: {
        'current_password': currentPassword,
        'password': password,
        're_password': passwordSubmit,
      },
    );
  }

  Future<ApiResponse<List<Request>>> getRequests() async {
    return await get(
      '/request',
      (json) => List<Request>.generate(
        json.length,
        (index) => Request.fromJson(json[index] as Map<String, dynamic>),
      ),
    );
  }

  Future<ApiResponse<dynamic>> sendRequest(
    String title,
    String release,
    String type,
  ) async {
    return await post(
      '/request',
      (json) => null,
      data: {'title': title, 'release': release, 'type': type},
    );
  }

  Future<ApiResponse<List<UserList>>> getUserLists(int page) async {
    return await get(
      '/lists',
      (json) => List<UserList>.generate(
        json.length,
        (index) => UserList.fromJson(json[index] as Map<String, dynamic>),
      ),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> createList(String title, String content) async {
    return await post(
      '/lists/create',
      (json) => null,
      data: {'title': title, 'content': content},
    );
  }

  Future<ApiResponse<dynamic>> deleteList(int id) async {
    return await delete('/lists/$id/delete', (json) => null);
  }

  Future<ApiResponse<dynamic>> editList(
    int id,
    String title,
    String content,
  ) async {
    return await put(
      '/lists/$id/update',
      (json) => null,
      data: {'title': title, 'content': content},
    );
  }

  Future<ApiResponse<dynamic>> addToList(int id, int postId) async {
    return await put(
      '/lists/$id/add_post',
      (json) => null,
      data: {'post_id': postId},
    );
  }

  Future<ApiResponse<dynamic>> removeFromList(int id, int postId) async {
    return await put(
      '/lists/$id/remove_post',
      (json) => null,
      data: {'post_id': postId},
    );
  }

  Future<ApiResponse<String>> updateAvatar(MultipartFile avatar) async {
    return await post(
      '/user/update_avatar',
      (json) => json['url'],
      data: {'avatar': avatar},
    );
  }

  Future<ApiResponse<List<Post>>> getWatchStatusPosts(
    String status,
    int page,
  ) async {
    return await get(
      '/watch_status_posts/$status',
      (json) => List<Post>.generate(
        json.length,
        (index) => Post.fromJson(json[index] as Map<String, dynamic>),
      ),
      queryParameters: {'page': page},
    );
  }

  Future<ApiResponse<dynamic>> deleteWatchStatusPost(
    String status,
    int postId,
  ) async {
    return await delete(
      '/watch_status_posts/$status/$postId/delete',
      (json) => null,
      data: {'_method': 'delete'},
    );
  }

  Future<ApiResponse<dynamic>> logout() async {
    return await post('/logout', (json) => null);
  }
}
