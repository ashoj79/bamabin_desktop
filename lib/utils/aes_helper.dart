import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

class AESHelper {
  String decrypt(String encryptedData) {
    try {
      final key = Key.fromUtf8('752729709BAMABiNR1sTuVwXyZoiWE49');
      final iv = IV.fromUtf8('aB7dEfGh1jKlMn0P');
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final bytes = _decodeBase64Loose(encryptedData);
      final encrypted = Encrypted(bytes);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      return '';
    }
  }

  /// ورودی‌های API گاهی Base64 استاندارد نیستند (فاصله، `\n`، `-`/`_` به‌جای `+`/`/`، padding کم).
  static Uint8List _decodeBase64Loose(String raw) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'\s'), '');
    s = s.replaceAll('-', '+').replaceAll('_', '/');
    final mod = s.length % 4;
    if (mod != 0) {
      s = s.padRight(s.length + (4 - mod), '=');
    }
    return base64Decode(s);
  }
}
