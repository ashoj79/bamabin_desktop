import 'package:bamabin_desktop/data/remote/model/user/device.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/utils/data_state.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._userRepository) : super(AuthInitial()) {
    on<AuthLoginWithUsernameEvent>(_onLoginWithUsername);
    on<AuthLoginWithTokenEvent>(_onLoginWithToken);
    on<AuthLoginWithGoogleEvent>(_onLoginWithGoogle);
    on<AuthSendOtpEvent>(_onSendOtp);
    on<AuthVerifyOtpEvent>(_onVerifyOtp);
    on<AuthDeleteDeviceEvent>(_onDeleteDevice);
    on<AuthRegisterEvent>(_onRegister);
  }

  final UserRepository _userRepository;

  Future<void> _onLoginWithUsername(
    AuthLoginWithUsernameEvent event,
    Emitter<AuthState> emit,
  ) async {
    final username = event.username.trim();
    final password = event.password.trim();

    if (username.isEmpty || password.isEmpty) {
      emit(AuthError('نام کاربری و رمز عبور را وارد کنید'));
      return;
    }

    if (password.length < 8) {
      emit(AuthError('رمز عبور باید حداقل ۸ کاراکتر باشد'));
      return;
    }

    emit(AuthLoading());

    final result = await _userRepository.loginWithUsername(username, password);
    if (result is DataSuccess) {
      emit(AuthSuccess());
      return;
    }

    await _handleAuthFailure(result.errorMessage, emit);
  }

  Future<void> _onRegister(
    AuthRegisterEvent event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    final username = event.username.trim();
    final password = event.password.trim();
    final phone = event.phone.trim();

    if (username.isEmpty) {
      emit(AuthError('نام کاربری را وارد کنید'));
      return;
    }
    if (email.isEmpty) {
      emit(AuthError('ایمیل را وارد کنید'));
      return;
    }
    if (!_isValidEmail(email)) {
      emit(AuthError('ایمیل معتبر نیست'));
      return;
    }
    if (password.length < 8) {
      emit(AuthError('رمز عبور باید حداقل ۸ کاراکتر باشد'));
      return;
    }
    if (phone.isNotEmpty && !_isValidPhone(phone)) {
      emit(AuthError('شماره موبایل باید با ۰۹ شروع شود و ۱۱ رقم باشد'));
      return;
    }

    emit(AuthLoading());
    final result = await _userRepository.register(
      email,
      username,
      password,
      password,
      phone: phone,
    );
    if (result is DataSuccess) {
      emit(AuthSuccess());
      return;
    }

    await _handleAuthFailure(result.errorMessage, emit);
  }

  Future<void> _onLoginWithToken(
    AuthLoginWithTokenEvent event,
    Emitter<AuthState> emit,
  ) async {
    final token = event.token.trim();
    if (token.isEmpty) {
      emit(AuthError('کد ورود نامعتبر است'));
      return;
    }

    emit(AuthLoading());
    final result = await _userRepository.loginWithApiKey(token);
    if (result is DataSuccess) {
      emit(AuthSuccess());
      return;
    }

    await _handleAuthFailure(result.errorMessage, emit);
  }

  Future<void> _onLoginWithGoogle(
    AuthLoginWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    final token = event.token.trim();
    if (token.isEmpty) {
      emit(AuthError('دریافت توکن گوگل ناموفق بود'));
      return;
    }

    emit(AuthLoading());
    final result = await _userRepository.loginWithGoogle(token);
    if (result is DataSuccess) {
      emit(AuthSuccess());
      return;
    }

    await _handleAuthFailure(result.errorMessage, emit);
  }

  Future<void> _onSendOtp(
    AuthSendOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final phone = event.phone.trim();
    if (!_isValidPhone(phone)) {
      emit(AuthError('شماره موبایل باید با ۰۹ شروع شود و ۱۱ رقم باشد'));
      return;
    }

    emit(AuthLoading());
    final result = await _userRepository.sendOtp(phone);
    if (result is DataSuccess) {
      emit(AuthOtpSent(phone));
      return;
    }
    emit(AuthError(result.errorMessage));
  }

  Future<void> _onVerifyOtp(
    AuthVerifyOtpEvent event,
    Emitter<AuthState> emit,
  ) async {
    final code = event.code.trim();
    if (!_isValidOtp(code)) {
      emit(AuthError('کد تأیید باید ۶ رقم باشد'));
      return;
    }

    emit(AuthLoading());
    final result = await _userRepository.verifyOtp(event.phone, code);
    if (result is DataSuccess) {
      emit(AuthSuccess());
      return;
    }

    await _handleAuthFailure(result.errorMessage, emit);
  }

  Future<void> _onDeleteDevice(
    AuthDeleteDeviceEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _userRepository.deleteDevice(event.index);
    if (result is DataSuccess) {
      emit(AuthDeviceDeleted());
      return;
    }
    emit(AuthError(result.errorMessage));
  }

  Future<void> _handleAuthFailure(
    String errorMessage,
    Emitter<AuthState> emit,
  ) async {
    if (errorMessage != 'device_limit') {
      emit(AuthError(errorMessage));
      return;
    }

    final devicesResult = await _userRepository.getDevices();
    if (devicesResult is DataError) {
      emit(AuthError(devicesResult.errorMessage));
      return;
    }
    emit(AuthDeviceLimit(devicesResult.data ?? const []));
  }

  bool _isValidPhone(String phone) => RegExp(r'^09[0-9]{9}$').hasMatch(phone);

  bool _isValidOtp(String code) => RegExp(r'^[0-9]{6}$').hasMatch(code);

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
}
