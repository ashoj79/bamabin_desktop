class AppVersion {
  final int version;
  final int requiresVersion;
  final String versionName;
  final String description;
  final String directLink;
  final String playStoreLink;
  bool needUpdate;
  bool isRequires;

  AppVersion({
    required this.version,
    required this.requiresVersion,
    required this.versionName,
    required this.description,
    required this.directLink,
    required this.playStoreLink,
    this.needUpdate = false,
    this.isRequires = false,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) => AppVersion(
    version: json['version'] ?? 0,
    requiresVersion: json['requires_version'] ?? 0,
    versionName: json['version_name'] ?? '',
    description: json['description'] ?? '',
    directLink: json['direct_download_link'] ?? '',
    playStoreLink: json['playstore_download_link'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'requires_version': requiresVersion,
    'version_name': versionName,
    'description': description,
    'direct_download_link': directLink,
    'playstore_download_link': playStoreLink,
  };
}
