import 'package:bamabin_desktop/utils/aes_helper.dart';

class UrlHelper {
  static final AESHelper _aesHelper = AESHelper();

  static String? _url;
  static String? _sslHash;
  static String? _socketUrl;

  static String? get url => _url;

  static String? get sslHash => _sslHash;

  static String? get socketUrl => _socketUrl;

  static void setData(String data) {
    final parts = _aesHelper.decrypt(data).split(';');
    if (parts.length >= 2) {
      _url = parts[0];
      _sslHash = parts[1];
      _socketUrl = parts[2];
    }
  }

  static String getDecryptedUrl() => _url ?? '';

  static String getDecryptedSSLHash() => _sslHash ?? '';

  static String getDecryptedSocketUrl() => _socketUrl ?? '';

  static void clear() {
    _url = null;
    _sslHash = null;
    _socketUrl = null;
  }
}
