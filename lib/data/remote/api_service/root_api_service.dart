import 'package:bamabin_desktop/config/dio_helper.dart';
import 'package:bamabin_desktop/data/remote/model/api_response.dart';
import 'package:bamabin_desktop/data/remote/model/app/startup_data.dart';
import 'package:dio/dio.dart';

class RootApiService {
  final DioHelper dioHelper;
  RootApiService(this.dioHelper);

  Future<Response<dynamic>> getBaseUrl() async {
    return await dioHelper.getServerCheckingLinkDio(1).get('');
  }

  Future<Response<dynamic>> getBaseUrl2(String export, String id) async {
    return await dioHelper
        .getServerCheckingLinkDio(2)
        .get('/uc', queryParameters: {'export': export, 'id': id});
  }

  Future<ApiResponse<StartupData>> getStartupData() async {
    var response = await dioHelper.getServerCheckingkDio().get('/api/startup');
    if (response.statusCode == 200) {
      return ApiResponse<StartupData>(
        status: response.statusCode == 200,
        data: StartupData.fromJson(response.data['result']),
      );
    }

    return ApiResponse<StartupData>(
      status: false,
      message: 'خطایی رخ داده است',
    );
  }
}
