import 'package:bamabin_desktop/config/dio_helper.dart';
import 'package:dio/dio.dart';

class UrlApiService {
  final DioHelper dioHelper;
  UrlApiService(this.dioHelper);

  Future<Response<dynamic>> getBaseUrl() async {
    return await dioHelper.getLinkDio(1).get('');
  }

  Future<Response<dynamic>> getBaseUrl2(String export, String id) async {
    return await dioHelper
        .getLinkDio(1)
        .get('/uc', queryParameters: {'export': export, 'id': id});
  }
}
