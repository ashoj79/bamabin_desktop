import 'package:bamabin_desktop/data/remote/api_service/url_api_service.dart';
import 'package:bamabin_desktop/data/remote/url_helper.dart';
import 'package:bamabin_desktop/data/local/shared_preference_helper.dart';
import 'package:bamabin_desktop/utils/data_state.dart';

class UrlRepository {
  final UrlApiService _urlApiService;
  final SharedPreferenceHelper _sharedPreferenceHelper;
  UrlRepository(this._urlApiService, this._sharedPreferenceHelper);

  Future<DataState<void>> getBaseUrl({int tryCount = 0, int type = 1}) async {
    if (tryCount >= 5) {
      if (type == 1) {
        return await getBaseUrl(tryCount: 0, type: 2);
      } else {
        return DataError('خطایی رخ داده است');
      }
    }

    try {
      final response = tryCount == 0
          ? await _urlApiService.getBaseUrl()
          : await _urlApiService.getBaseUrl2(
              'download',
              '1q0YNxxQ2r1uOO46MUdZF3FqrkbEh5Fr5',
            );
      if (response.statusCode == 200) {
        UrlHelper.setData(response.data as String);
        await _sharedPreferenceHelper.setUrlData(response.data as String);
        return DataSuccess();
      }
    } catch (_) {}

    return await getBaseUrl(tryCount: tryCount + 1, type: type);
  }
}
