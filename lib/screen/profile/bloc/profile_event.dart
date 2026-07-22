part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

final class ProfileLoadEvent extends ProfileEvent {}

final class ProfileLogoutEvent extends ProfileEvent {}

final class ProfileDeleteDeviceEvent extends ProfileEvent {
  ProfileDeleteDeviceEvent({required this.index});

  final int index;
}

final class ProfileEditEvent extends ProfileEvent {
  ProfileEditEvent({
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.email,
    required this.city,
    required this.phone,
    required this.description,
  });

  final String firstName;
  final String lastName;
  final String nickname;
  final String email;
  final String city;
  final String phone;
  final String description;
}

final class ProfileUpdateAvatarEvent extends ProfileEvent {
  ProfileUpdateAvatarEvent({required this.filePath});

  final String filePath;
}

final class ProfileUpdatePasswordEvent extends ProfileEvent {
  ProfileUpdatePasswordEvent({
    required this.currentPassword,
    required this.password,
    required this.passwordSubmit,
  });

  final String currentPassword;
  final String password;
  final String passwordSubmit;
}

enum ProfilePlaybackSetting {
  videoSpeed,
  subtitleSize,
  subtitleFont,
  subtitleBgColor,
  subtitleTextColor,
  subtitleMargin,
}

final class ProfileUpdatePlaybackSettingEvent extends ProfileEvent {
  ProfileUpdatePlaybackSettingEvent({
    required this.setting,
    required this.value,
  });

  final ProfilePlaybackSetting setting;
  final int value;
}
