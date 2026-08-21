import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  final SharedPreferences _sharedPreferences;

  SharedPreferenceHelper(this._sharedPreferences);

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

  Future<void> setUrlData(String url) async {
    await _sharedPreferences.setString(_keyUrlData, url);
  }

  String getUrlData() {
    return _sharedPreferences.getString(_keyUrlData) ?? '';
  }

  String getApiKey() {
    return _sharedPreferences.getString(_keyApiKey) ?? '';
  }

  Future<void> setApiKey(String apiKey) async {
    await _sharedPreferences.setString(_keyApiKey, apiKey);
  }

  String getUsername() {
    return _sharedPreferences.getString(_keyUsername) ?? '';
  }

  Future<void> setUsername(String username) async {
    await _sharedPreferences.setString(_keyUsername, username);
  }

  String getEmail() {
    return _sharedPreferences.getString(_keyEmail) ?? '';
  }

  Future<void> setEmail(String email) async {
    await _sharedPreferences.setString(_keyEmail, email);
  }

  String getAvatar() {
    return _sharedPreferences.getString(_keyAvatar) ?? '';
  }

  Future<void> setAvatar(String avatar) async {
    await _sharedPreferences.setString(_keyAvatar, avatar);
  }

  String getFirstName() {
    return _sharedPreferences.getString(_keyFirstName) ?? '';
  }

  Future<void> setFirstName(String firstName) async {
    await _sharedPreferences.setString(_keyFirstName, firstName);
  }

  String getLastName() {
    return _sharedPreferences.getString(_keyLastName) ?? '';
  }

  Future<void> setLastName(String lastName) async {
    await _sharedPreferences.setString(_keyLastName, lastName);
  }

  String getNickname() {
    return _sharedPreferences.getString(_keyNickname) ?? '';
  }

  Future<void> setNickname(String nickname) async {
    await _sharedPreferences.setString(_keyNickname, nickname);
  }

  String getPhone() {
    return _sharedPreferences.getString(_keyPhone) ?? '';
  }

  Future<void> setPhone(String phone) async {
    await _sharedPreferences.setString(_keyPhone, phone);
  }

  String getCity() {
    return _sharedPreferences.getString(_keyCity) ?? '';
  }

  Future<void> setCity(String city) async {
    await _sharedPreferences.setString(_keyCity, city);
  }

  String getDescription() {
    return _sharedPreferences.getString(_keyDescription) ?? '';
  }

  Future<void> setDescription(String description) async {
    await _sharedPreferences.setString(_keyDescription, description);
  }

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
    await Future.wait([
      _sharedPreferences.remove(_keyApiKey),
      _sharedPreferences.remove(_keyUsername),
      _sharedPreferences.remove(_keyEmail),
      _sharedPreferences.remove(_keyAvatar),
      _sharedPreferences.remove(_keyFirstName),
      _sharedPreferences.remove(_keyLastName),
      _sharedPreferences.remove(_keyNickname),
      _sharedPreferences.remove(_keyPhone),
      _sharedPreferences.remove(_keyCity),
      _sharedPreferences.remove(_keyDescription),
    ]);
  }
}
