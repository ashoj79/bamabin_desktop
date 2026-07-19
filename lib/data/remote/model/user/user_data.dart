import 'vip_info.dart';

class UserData {
  final String avatar;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String nickname;
  final String phone;
  final String city;
  final String description;
  final VipInfo? vipInfo;

  UserData({
    required this.avatar,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.phone = '',
    this.city = '',
    this.description = '',
    this.vipInfo,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    avatar: json['avatar'] ?? '',
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    nickname: json['nickname'] ?? '',
    phone: json['phone'] ?? '',
    city: json['city'] ?? '',
    description: json['description'] ?? '',
    vipInfo:
        json['vip_info'] != null ? VipInfo.fromJson(json['vip_info']) : null,
  );
}
