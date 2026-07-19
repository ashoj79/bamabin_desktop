import 'package:bamabin_desktop/config/dio_helper.dart';
import 'package:dio/dio.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';

class BaseApiService {
  final DioHelper dioHelper;

  BaseApiService(this.dioHelper);

  ApiResponse<T> parseResponse<T>(
    Response<dynamic> response,
    T Function(dynamic json) fromJson,
  ) {
    if (response.statusCode == null) {
      return ApiResponse<T>(
        status: false,
        message: 'در سرور خطایی رخ داده است',
      );
    }

    int statusCode = response.statusCode!;

    if (statusCode >= 500) {
      return ApiResponse<T>(
        status: false,
        message: 'در سرور خطایی رخ داده است',
      );
    } else if (statusCode >= 400) {
      return ApiResponse<T>(status: false, message: response.data['message']);
    } else {
      return ApiResponse<T>.fromJson(response.data, fromJson);
    }
  }

  Future<ApiResponse<T>> get<T>(
    String url,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioHelper.getDio().get(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return parseResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        status: false,
        message: 'مشکلی در اتصال به سرور رخ داده است',
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String url,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioHelper.getDio().post(
        url,
        data: data != null ? FormData.fromMap(data) : null,
        cancelToken: cancelToken,
      );
      return parseResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        status: false,
        message: 'مشکلی در اتصال به سرور رخ داده است',
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String url,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioHelper.getDio().put(
        url,
        data: data,
        queryParameters: {'_method': 'put'},
        cancelToken: cancelToken,
      );
      return parseResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        status: false,
        message: 'مشکلی در اتصال به سرور رخ داده است',
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String url,
    T Function(dynamic json) fromJson, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await dioHelper.getDio().delete(
        url,
        data: data,
        queryParameters: {'method': 'delete'},
        cancelToken: cancelToken,
      );
      return parseResponse(response, fromJson);
    } catch (e) {
      return ApiResponse<T>(
        status: false,
        message: 'مشکلی در اتصال به سرور رخ داده است',
      );
    }
  }
}
