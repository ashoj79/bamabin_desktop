part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLogoutLoading extends ProfileState {}

final class ProfileLogoutSuccess extends ProfileState {}

final class ProfileBusy extends ProfileState {}

final class ProfileActionSuccess extends ProfileState {
  ProfileActionSuccess(this.message);

  final String message;
}

final class ProfileError extends ProfileState {
  ProfileError(this.message);

  final String message;
}

final class ProfileLoaded extends ProfileState {
  ProfileLoaded({
    this.dashboard,
    this.isDashboardLoading = false,
    this.playStatus = const [],
    this.isPlayStatusLoading = false,
    this.devices = const [],
    this.isDevicesLoading = false,
    this.videoSpeed = 1,
    this.subtitleSize = 30,
    this.subtitleFont = 1,
    this.subtitleBgColor = 2,
    this.subtitleTextColor = 0,
    this.subtitleMargin = 69,
    required this.username,
    required this.email,
    required this.phone,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.city,
    required this.description,
  });

  final Dashboard? dashboard;
  final bool isDashboardLoading;
  final List<PlayStatus> playStatus;
  final bool isPlayStatusLoading;
  final List<Device> devices;
  final bool isDevicesLoading;
  final int videoSpeed;
  final int subtitleSize;
  final int subtitleFont;
  final int subtitleBgColor;
  final int subtitleTextColor;
  final int subtitleMargin;
  final String username;
  final String email;
  final String phone;
  final String nickname;
  final String firstName;
  final String lastName;
  final String city;
  final String description;

  String get displayName {
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (nickname.trim().isNotEmpty) return nickname.trim();
    return username;
  }

  ProfileLoaded copyWith({
    Dashboard? dashboard,
    bool? isDashboardLoading,
    List<PlayStatus>? playStatus,
    bool? isPlayStatusLoading,
    List<Device>? devices,
    bool? isDevicesLoading,
    int? videoSpeed,
    int? subtitleSize,
    int? subtitleFont,
    int? subtitleBgColor,
    int? subtitleTextColor,
    int? subtitleMargin,
    String? email,
    String? phone,
    String? nickname,
    String? firstName,
    String? lastName,
    String? city,
    String? description,
  }) {
    return ProfileLoaded(
      dashboard: dashboard ?? this.dashboard,
      isDashboardLoading: isDashboardLoading ?? this.isDashboardLoading,
      playStatus: playStatus ?? this.playStatus,
      isPlayStatusLoading: isPlayStatusLoading ?? this.isPlayStatusLoading,
      devices: devices ?? this.devices,
      isDevicesLoading: isDevicesLoading ?? this.isDevicesLoading,
      videoSpeed: videoSpeed ?? this.videoSpeed,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      subtitleFont: subtitleFont ?? this.subtitleFont,
      subtitleBgColor: subtitleBgColor ?? this.subtitleBgColor,
      subtitleTextColor: subtitleTextColor ?? this.subtitleTextColor,
      subtitleMargin: subtitleMargin ?? this.subtitleMargin,
      username: username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      city: city ?? this.city,
      description: description ?? this.description,
    );
  }
}
