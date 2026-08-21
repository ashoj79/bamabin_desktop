import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  SharedPreferenceHelper(this._sharedPreferences, [this._secureStorage]);

  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage? _secureStorage;

  /// Keychain prompts for password on unsigned macOS builds; use prefs instead.
  static bool get _useSecureStorage =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.macOS;

  static const _keyUrlData = 'urlData';
  static const _keyAllowAccess = 'allowAccess';
  static const _keyApiKey = 'apiKey';
  static const _keyUsername = 'username';
  static const _keyEmail = 'email';
  static const _keyAvatar = 'avatar';
  static const _keyFirstName = 'first_name';
  static const _keyLastName = 'last_name';
  static const _keyNickname = 'nickname';
  static const _keyPhone = 'phone';
  static const _keyCity = 'city';
  static const _keyDescription = 'description';
  static const _migrationDoneKey = 'auth_migrated_to_secure_v1';

  static const _secureKeys = [
    _keyApiKey,
    _keyUsername,
    _keyEmail,
    _keyAvatar,
    _keyFirstName,
    _keyLastName,
    _keyNickname,
    _keyPhone,
    _keyCity,
    _keyDescription,
  ];

  final Map<String, String> _secureCache = {};

  Future<void> init() async {
    if (_useSecureStorage) {
      await _migrateAuthToSecureStorage();
    }
    await _loadSecureCache();
  }

  Future<void> _migrateAuthToSecureStorage() async {
    if (_sharedPreferences.getBool(_migrationDoneKey) == true) return;

    for (final key in _secureKeys) {
      final value = _sharedPreferences.getString(key);
      if (value != null && value.isNotEmpty) {
        final wrote = await _trySecureWrite(key, value);
        if (wrote) {
          await _sharedPreferences.remove(key);
        }
      }
    }

    await _sharedPreferences.setBool(_migrationDoneKey, true);
  }

  Future<void> _loadSecureCache() async {
    for (final key in _secureKeys) {
      if (_useSecureStorage) {
        _secureCache[key] = await _trySecureRead(key) ??
            _sharedPreferences.getString(key) ??
            '';
      } else {
        _secureCache[key] = _sharedPreferences.getString(key) ?? '';
      }
    }
  }

  Future<void> _setSecure(String key, String value) async {
    _secureCache[key] = value;
    if (!_useSecureStorage) {
      if (value.isEmpty) {
        await _sharedPreferences.remove(key);
      } else {
        await _sharedPreferences.setString(key, value);
      }
      return;
    }

    if (value.isEmpty) {
      await _trySecureDelete(key);
      await _sharedPreferences.remove(key);
    } else {
      final wrote = await _trySecureWrite(key, value);
      if (!wrote) {
        await _sharedPreferences.setString(key, value);
      } else {
        await _sharedPreferences.remove(key);
      }
    }
  }

  String _getSecure(String key) => _secureCache[key] ?? '';

  Future<String?> _trySecureRead(String key) async {
    final storage = _secureStorage;
    if (storage == null) return null;
    try {
      return await storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  Future<bool> _trySecureWrite(String key, String value) async {
    final storage = _secureStorage;
    if (storage == null) return false;
    try {
      await storage.write(key: key, value: value);
      return true;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _trySecureDelete(String key) async {
    final storage = _secureStorage;
    if (storage == null) return;
    try {
      await storage.delete(key: key);
    } on PlatformException {
      // Keychain may be unavailable on unsigned macOS builds.
    }
  }

  Future<void> setUrlData(String url) async {
    await _sharedPreferences.setString(_keyUrlData, url);
  }

  String getUrlData() {
    return _sharedPreferences.getString(_keyUrlData) ?? '';
  }

  String getApiKey() => _getSecure(_keyApiKey);

  Future<void> setApiKey(String apiKey) => _setSecure(_keyApiKey, apiKey);

  String getUsername() => _getSecure(_keyUsername);

  Future<void> setUsername(String username) =>
      _setSecure(_keyUsername, username);

  String getEmail() => _getSecure(_keyEmail);

  Future<void> setEmail(String email) => _setSecure(_keyEmail, email);

  String getAvatar() => _getSecure(_keyAvatar);

  Future<void> setAvatar(String avatar) => _setSecure(_keyAvatar, avatar);

  String getFirstName() => _getSecure(_keyFirstName);

  Future<void> setFirstName(String firstName) =>
      _setSecure(_keyFirstName, firstName);

  String getLastName() => _getSecure(_keyLastName);

  Future<void> setLastName(String lastName) =>
      _setSecure(_keyLastName, lastName);

  String getNickname() => _getSecure(_keyNickname);

  Future<void> setNickname(String nickname) =>
      _setSecure(_keyNickname, nickname);

  String getPhone() => _getSecure(_keyPhone);

  Future<void> setPhone(String phone) => _setSecure(_keyPhone, phone);

  String getCity() => _getSecure(_keyCity);

  Future<void> setCity(String city) => _setSecure(_keyCity, city);

  String getDescription() => _getSecure(_keyDescription);

  Future<void> setDescription(String description) =>
      _setSecure(_keyDescription, description);

  Future<void> setSubTextColor(int data) async {
    await _sharedPreferences.setInt('subtitleTextColor', data);
  }

  Future<int> getSubTextColor() async {
    return _sharedPreferences.getInt('subtitleTextColor') ?? 0;
  }

  Future<void> setSubBgColor(int data) async {
    await _sharedPreferences.setInt('subtitleBgColor', data);
  }

  Future<int> getSubBgColor() async {
    return _sharedPreferences.getInt('subtitleBgColor') ?? 2;
  }

  Future<void> setSubFont(int data) async {
    await _sharedPreferences.setInt('subtitleFont', data);
  }

  Future<int> getSubFont() async {
    return _sharedPreferences.getInt('subtitleFont') ?? 1;
  }

  Future<void> setSubSize(int data) async {
    await _sharedPreferences.setInt('subtitleSize', data);
  }

  Future<int> getSubSize() async {
    return _sharedPreferences.getInt('subtitleSize') ?? 30;
  }

  Future<void> setSubMargin(int data) async {
    await _sharedPreferences.setInt('subtitleMargin', data);
  }

  Future<int> getSubMargin() async {
    return _sharedPreferences.getInt('subtitleMargin') ?? 69;
  }

  Future<void> setVideoSpeed(int data) async {
    await _sharedPreferences.setInt('videoSpeed', data);
  }

  Future<int> getVideoSpeed() async {
    return _sharedPreferences.getInt('videoSpeed') ?? 1;
  }

  Future<void> setAllowAccess(bool data) async {
    await _sharedPreferences.setBool(_keyAllowAccess, data);
  }

  Future<bool> getAllowAccess() async {
    return _sharedPreferences.getBool(_keyAllowAccess) ?? false;
  }

  Future<void> clearAuthData() async {
    for (final key in _secureKeys) {
      _secureCache[key] = '';
    }
    await Future.wait([
      if (_useSecureStorage)
        for (final key in _secureKeys) _trySecureDelete(key),
      for (final key in _secureKeys) _sharedPreferences.remove(key),
    ]);
  }
}
