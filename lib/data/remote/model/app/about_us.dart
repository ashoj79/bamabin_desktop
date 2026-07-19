class AboutUs {
  final String about;
  final String instagram;
  final String telegram;

  AboutUs({
    required this.about,
    required this.instagram,
    required this.telegram,
  });

  factory AboutUs.fromJson(Map<String, dynamic> json) => AboutUs(
    about: json['about'] ?? '',
    instagram: json['instagram_page'] ?? '',
    telegram: json['telegram_channel'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'about': about,
    'instagram_page': instagram,
    'telegram_channel': telegram,
  };
}
