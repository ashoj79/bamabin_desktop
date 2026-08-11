import 'package:bamabin_desktop/data/remote/model/user/dashboard.dart';
import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:bamabin_desktop/data/remote/model/user/play_status.dart';
import 'package:bamabin_desktop/repository/app_repository.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._userRepository, this._appRepository)
    : super(ProfileInitial()) {
    on<ProfileLoadEvent>(_onLoad);
    on<ProfileLogoutEvent>(_onLogout);
    on<ProfileDeleteDeviceEvent>(_onDeleteDevice);
    on<ProfileEditEvent>(_onEdit);
    on<ProfileUpdateAvatarEvent>(_onUpdateAvatar);
    on<ProfileUpdatePasswordEvent>(_onUpdatePassword);
    on<ProfileUpdatePlaybackSettingEvent>(_onUpdatePlaybackSetting);
    on<ProfileTvRemoteLoginEvent>(_onTvRemoteLogin);
  }

  final UserRepository _userRepository;
  final AppRepository _appRepository;

  Future<ProfileLoaded> _baseProfile() async {
    final results = await Future.wait([
      _appRepository.getVideoSpeed(),
      _appRepository.getSubSize(),
      _appRepository.getSubFont(),
      _appRepository.getSubBgColor(),
      _appRepository.getSubTextColor(),
      _appRepository.getSubMargin(),
    ]);

    return ProfileLoaded(
      isDashboardLoading: true,
      isPlayStatusLoading: true,
      isDevicesLoading: true,
      videoSpeed: results[0],
      subtitleSize: results[1],
      subtitleFont: results[2],
      subtitleBgColor: results[3],
      subtitleTextColor: results[4],
      subtitleMargin: results[5],
      username: _userRepository.getUsername(),
      email: _userRepository.getEmail(),
      phone: _userRepository.getPhone(),
      nickname: _userRepository.getNickname(),
      firstName: _userRepository.getFirstName(),
      lastName: _userRepository.getLastName(),
      city: _userRepository.getCity(),
      description: _userRepository.getDescription(),
    );
  }

  Future<void> _onLoad(
    ProfileLoadEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(await _baseProfile());

    final dashboardResult = await _userRepository.getDashboard();
    if (dashboardResult is DataError) {
      emit(ProfileError(dashboardResult.errorMessage));
      return;
    }

    var loaded = (state as ProfileLoaded).copyWith(
      dashboard: dashboardResult.data,
      isDashboardLoading: false,
    );
    emit(loaded);

    final playStatusResult = await _userRepository.getPlayStatus(page: 1);
    if (playStatusResult is DataSuccess) {
      loaded = loaded.copyWith(
        playStatus: playStatusResult.data ?? const [],
        isPlayStatusLoading: false,
      );
    } else {
      loaded = loaded.copyWith(isPlayStatusLoading: false);
    }
    emit(loaded);

    final devicesResult = await _userRepository.getDevices();
    if (devicesResult is DataSuccess) {
      loaded = loaded.copyWith(
        devices: devicesResult.data ?? const [],
        isDevicesLoading: false,
      );
    } else {
      loaded = loaded.copyWith(isDevicesLoading: false);
    }
    emit(loaded);
  }

  Future<void> _onLogout(
    ProfileLogoutEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLogoutLoading());
    try {
      await _userRepository.logout(true);
      emit(ProfileLogoutSuccess());
    } catch (_) {
      emit(ProfileError('خطایی رخ داده است'));
    }
  }

  Future<void> _onDeleteDevice(
    ProfileDeleteDeviceEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileBusy());
    final result = await _userRepository.deleteDevice(event.index);
    if (result is DataError) {
      emit(ProfileError(result.errorMessage));
      emit(current);
      return;
    }
    if (event.index == -1) {
      emit(ProfileLogoutSuccess());
      return;
    }

    final devices = List<Device>.from(current.devices)..removeAt(event.index);
    emit(ProfileActionSuccess('دستگاه با موفقیت حذف شد'));
    emit(current.copyWith(devices: devices));
  }

  Future<void> _onEdit(
    ProfileEditEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileBusy());
    final result = await _userRepository.editProfile(
      event.firstName,
      event.lastName,
      event.nickname,
      event.email,
      event.city,
      event.phone,
      event.description,
    );
    if (result is DataError) {
      emit(ProfileError(result.errorMessage));
      emit(current);
      return;
    }

    emit(ProfileActionSuccess('اطلاعات پروفایل ذخیره شد'));
    emit(
      current.copyWith(
        firstName: event.firstName,
        lastName: event.lastName,
        nickname: event.nickname,
        email: event.email,
        city: event.city,
        phone: event.phone,
        description: event.description,
      ),
    );
  }

  Future<void> _onUpdateAvatar(
    ProfileUpdateAvatarEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileBusy());
    final result = await _userRepository.updateAvatar(event.filePath);
    if (result is DataError) {
      emit(ProfileError(result.errorMessage));
      emit(current);
      return;
    }

    final avatar = _userRepository.getAvatar();
    final dashboard = current.dashboard;
    emit(ProfileActionSuccess('تصویر پروفایل به‌روزرسانی شد'));
    emit(
      current.copyWith(
        dashboard: dashboard == null
            ? null
            : Dashboard(
                specialDomain: dashboard.specialDomain,
                avatar: avatar.isNotEmpty ? avatar : dashboard.avatar,
                vipTime: dashboard.vipTime,
                vipTimePercentage: dashboard.vipTimePercentage,
                vipEndDate: dashboard.vipEndDate,
                registeredAt: dashboard.registeredAt,
                requestsCount: dashboard.requestsCount,
                listsCount: dashboard.listsCount,
                commentsCount: dashboard.commentsCount,
                favoritesCount: dashboard.favoritesCount,
                watchingCount: dashboard.watchingCount,
                notWatchedCount: dashboard.notWatchedCount,
                watchedCount: dashboard.watchedCount,
                devicesCount: dashboard.devicesCount,
              ),
      ),
    );
  }

  Future<void> _onUpdatePassword(
    ProfileUpdatePasswordEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    if (event.password != event.passwordSubmit) {
      emit(ProfileError('رمز عبور جدید و تکرار آن یکسان نیست'));
      emit(current);
      return;
    }

    emit(ProfileBusy());
    final result = await _userRepository.updatePassword(
      event.currentPassword,
      event.password,
      event.passwordSubmit,
    );
    if (result is DataError) {
      emit(ProfileError(result.errorMessage));
      emit(current);
      return;
    }

    emit(ProfileActionSuccess('رمز عبور با موفقیت به‌روزرسانی شد'));
    emit(current);
  }

  Future<void> _onUpdatePlaybackSetting(
    ProfileUpdatePlaybackSettingEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    switch (event.setting) {
      case ProfilePlaybackSetting.videoSpeed:
        await _appRepository.setVideoSpeed(event.value);
        emit(current.copyWith(videoSpeed: event.value));
      case ProfilePlaybackSetting.subtitleSize:
        await _appRepository.setSubSize(event.value);
        emit(current.copyWith(subtitleSize: event.value));
      case ProfilePlaybackSetting.subtitleFont:
        await _appRepository.setSubFont(event.value);
        emit(current.copyWith(subtitleFont: event.value));
      case ProfilePlaybackSetting.subtitleBgColor:
        await _appRepository.setSubBgColor(event.value);
        emit(current.copyWith(subtitleBgColor: event.value));
      case ProfilePlaybackSetting.subtitleTextColor:
        await _appRepository.setSubTextColor(event.value);
        emit(current.copyWith(subtitleTextColor: event.value));
      case ProfilePlaybackSetting.subtitleMargin:
        await _appRepository.setSubMargin(event.value);
        emit(current.copyWith(subtitleMargin: event.value));
    }
  }

  Future<void> _onTvRemoteLogin(
    ProfileTvRemoteLoginEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    final token = event.token.trim();
    if (token.isEmpty) {
      emit(ProfileError('لطفا کد ورود تلویزیون را وارد کنید'));
      emit(current);
      return;
    }

    emit(ProfileBusy());
    final result = await _userRepository.tvRemoteLogin(token);
    if (result is DataError) {
      final message = result.errorMessage == 'device_limit'
          ? 'حداکثر تعداد دستگاه‌های مجاز پر شده است. یکی از دستگاه‌ها را حذف کنید.'
          : result.errorMessage;
      emit(ProfileError(message));
      emit(current);
      return;
    }

    emit(ProfileActionSuccess('ورود تلویزیون با موفقیت انجام شد'));
    emit(current);
  }
}
