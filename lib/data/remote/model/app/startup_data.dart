import '../videos/genre.dart';
import '../videos/post.dart';
import '../user/vip_info.dart';
import 'app_version.dart';
import 'about_us.dart';

class StartupData {
  final List<Genre> genres;
  final AppVersion version;
  final AboutUs aboutUs;
  final VipInfo vipInfo;
  final List<Post> promotions;
  final String supportLink;
  final bool isAuth;
  final String urlHash;
  final String? newToken;
  final bool haveUnreadNotif;
  final String appType;

  StartupData({
    required this.genres,
    required this.version,
    required this.aboutUs,
    required this.vipInfo,
    required this.promotions,
    required this.supportLink,
    required this.isAuth,
    this.urlHash = '',
    this.newToken,
    this.haveUnreadNotif = false,
    this.appType = '',
  });

  factory StartupData.fromJson(Map<String, dynamic> json) => StartupData(
    genres: (json['genres'] as List?)
            ?.map((e) => Genre.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    version: AppVersion.fromJson(json['version'] ?? {}),
    aboutUs: AboutUs.fromJson(json['about_us'] ?? {}),
    vipInfo: VipInfo.fromJson(json['vip_info'] ?? {}),
    promotions: (json['promotions'] as List?)
            ?.map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    supportLink: json['support_link'] ?? '',
    isAuth: json['is_auth'] ?? false,
    urlHash: json['url_hash'] ?? '',
    newToken: json['new_token'],
    haveUnreadNotif: json['have_unread_notif'] ?? false,
    appType: json['app_type'] ?? '',
  );
}
