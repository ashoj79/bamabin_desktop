import 'dart:async';
import 'dart:math';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/config/google_auth.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/devices_alert.dart';
import 'package:bamabin_desktop/core/widgets/dialogs.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/remote/url_helper.dart';
import 'package:bamabin_desktop/screen/auth/bloc/auth_bloc.dart';
import 'package:bamabin_desktop/utils/deep_link_handler.dart';
import 'package:bamabin_desktop/utils/socket_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:qr_flutter/qr_flutter.dart';

const _authBg = Color(0xFF0C0C14);
const _authSurface = Color(0xFF14141F);
const _authField = Color(0xFF1C1C2B);
const _authMuted = Color(0xFFA8AABB);
const _authInk = Color(0xFFF4F4F8);
const _authSubtle = Color(0xFF6F7182);
const _authLabel = Color(0xFFC9CBDB);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _isLogin = true;
  var _isPasswordMethod = true;
  var _otpSent = false;
  var _agreeTerms = false;
  var _qrExpanded = true;
  var _obscurePassword = true;
  var _obscureSignupPassword = true;
  String? _qrLink;
  var _loadingDialogShown = false;
  var _isUsingGoogle = false;
  var _googleSigningIn = false;

  final _googleSignIn = GoogleSignIn(
    params: const GoogleSignInParams(
      clientId: GoogleAuthConfig.clientId,
      clientSecret: GoogleAuthConfig.clientSecret,
      scopes: ['openid', 'profile', 'email'],
    ),
  );

  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  final _otpPhone = TextEditingController();
  final _otpDigits = List.generate(6, (_) => TextEditingController());
  final _otpFocus = List.generate(6, (_) => FocusNode());
  var _otpPhoneNormalized = '';
  String? _socketApiKey;
  Timer? _otpResendTimer;
  var _otpResendSeconds = 0;

  static const _otpResendCooldown = 120;

  final _signupUsername = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  final _signupPhone = TextEditingController();

  static const _tokenChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  var _socketToken = '';

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  @override
  void dispose() {
    _otpResendTimer?.cancel();
    SocketHelper.disconnect();
    _loginUsername.dispose();
    _loginPassword.dispose();
    _otpPhone.dispose();
    for (final c in _otpDigits) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    _signupUsername.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    _signupPhone.dispose();
    super.dispose();
  }

  String _randomToken() {
    final random = Random.secure();
    return List.generate(
      5,
      (_) => _tokenChars[random.nextInt(_tokenChars.length)],
    ).join();
  }

  dynamic _payload(dynamic data) {
    if (data is List && data.isNotEmpty) return data.first;
    return data;
  }

  void _connectSocket() {
    final socketUrl = UrlHelper.getDecryptedSocketUrl();
    if (socketUrl.isEmpty) return;

    _socketToken = _randomToken();
    SocketHelper.connect(socketUrl);

    final socket = SocketHelper.socket;
    socket.on('connect', (_) {
      socket.emit('check_token', _socketToken);
    });

    socket.on('new_token', (_) {
      _socketToken = _randomToken();
      socket.emit('check_token', _socketToken);
    });

    socket.on('qr_code', (data) {
      final payload = _payload(data);
      final link = payload is Map ? payload['data']?.toString() : null;
      if (link == null || link.isEmpty || !mounted) return;
      setState(() {
        _qrLink = link;
        _qrExpanded = true;
      });
    });

    socket.on('api_key', (data) {
      final payload = _payload(data);
      final apiKey = payload is Map ? payload['api_key']?.toString() : null;
      if (apiKey == null || apiKey.isEmpty || !mounted) return;
      _socketApiKey = apiKey;
      _isUsingGoogle = false;
      context.read<AuthBloc>().add(AuthLoginWithTokenEvent(token: apiKey));
    });

    socket.on('disconnect', (_) {
      if (!mounted) return;
      setState(() => _qrLink = null);
    });
  }

  void _refreshQr() {
    if (!SocketHelper.hasSocket) {
      _connectSocket();
      return;
    }
    setState(() => _qrLink = null);
    _socketToken = _randomToken();
    SocketHelper.socket.emit('check_token', _socketToken);
  }

  void _submitLogin() {
    FocusScope.of(context).unfocus();
    _socketApiKey = null;
    _isUsingGoogle = false;
    context.read<AuthBloc>().add(
      AuthLoginWithUsernameEvent(
        username: _loginUsername.text,
        password: _loginPassword.text,
      ),
    );
  }

  void _submitSendOtp() {
    if (_otpResendSeconds > 0) return;
    FocusScope.of(context).unfocus();
    _socketApiKey = null;
    _isUsingGoogle = false;
    context.read<AuthBloc>().add(
      AuthSendOtpEvent(phone: _otpPhone.text),
    );
  }

  String _otpCode() => _otpDigits.map((c) => c.text).join();

  void _submitVerifyOtp() {
    FocusScope.of(context).unfocus();
    _socketApiKey = null;
    _isUsingGoogle = false;
    context.read<AuthBloc>().add(
      AuthVerifyOtpEvent(
        phone: _otpPhoneNormalized.isNotEmpty
            ? _otpPhoneNormalized
            : _otpPhone.text.trim(),
        code: _otpCode(),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_googleSigningIn) return;
    _googleSigningIn = true;
    _isUsingGoogle = true;
    _socketApiKey = null;

    try {
      if (GoogleAuthConfig.clientSecret.isEmpty) {
        if (!mounted) return;
        showBamabinSnackbar(
          context,
          'برای ورود با گوگل، GOOGLE_CLIENT_SECRET را تنظیم کنید',
        );
        return;
      }

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final credentials = await _googleSignIn.signIn();
      final idToken = credentials?.idToken;
      if (idToken == null || idToken.isEmpty) {
        if (!mounted || credentials == null) return;
        showBamabinSnackbar(context, 'دریافت توکن گوگل ناموفق بود');
        return;
      }

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      if (!mounted) return;
      context.read<AuthBloc>().add(AuthLoginWithGoogleEvent(token: idToken));
    } catch (_) {
      if (!mounted) return;
      showBamabinSnackbar(context, 'ورود با گوگل ناموفق بود');
    } finally {
      _googleSigningIn = false;
    }
  }

  void _clearOtpDigits() {
    for (final c in _otpDigits) {
      c.clear();
    }
  }

  void _startOtpResendCooldown() {
    _otpResendTimer?.cancel();
    setState(() => _otpResendSeconds = _otpResendCooldown);
    _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpResendSeconds <= 1) {
        timer.cancel();
        setState(() => _otpResendSeconds = 0);
        return;
      }
      setState(() => _otpResendSeconds--);
    });
  }

  void _retryAfterDeviceDeleted() {
    if (_isUsingGoogle) {
      _signInWithGoogle();
      return;
    }
    final apiKey = _socketApiKey;
    if (apiKey != null && apiKey.isNotEmpty) {
      context.read<AuthBloc>().add(AuthLoginWithTokenEvent(token: apiKey));
      return;
    }
    if (!_isPasswordMethod && _otpSent) {
      _submitVerifyOtp();
    } else {
      _submitLogin();
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageWidth = () {
      final max = MediaQuery.sizeOf(context).width - 120;
      final target = _isLogin ? 720.0 : 420.0;
      return max < target ? max : target;
    }();

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          if (!_loadingDialogShown) {
            _loadingDialogShown = true;
            showLoadingDialog(context);
          }
          return;
        }

        if (_loadingDialogShown) {
          Navigator.of(context, rootNavigator: true).pop();
          _loadingDialogShown = false;
        }

        if (state is AuthError) {
          showBamabinSnackbar(context, state.message);
        } else if (state is AuthOtpSent) {
          setState(() {
            _otpSent = true;
            _otpPhoneNormalized = state.phone;
            _otpPhone.text = state.phone;
            _clearOtpDigits();
          });
          _startOtpResendCooldown();
        } else if (state is AuthSuccess) {
          context.go(Routes.main);
          DeepLinkHandler.instance.markReady();
        } else if (state is AuthDeviceLimit) {
          showDevicesAlert(
            context,
            devices: state.devices,
            onClick: (index) {
              context.read<AuthBloc>().add(
                AuthDeleteDeviceEvent(index: index),
              );
            },
          );
        } else if (state is AuthDeviceDeleted) {
          _retryAfterDeviceDeleted();
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: _authBg,
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(60, 44, 60, 50),
                  child: SizedBox(
                    width: pageWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _BrandHeader(),
                        const SizedBox(height: 26),
                        Center(
                          child: _TabPills(
                            isLogin: _isLogin,
                            onLogin: () => setState(() {
                              _isLogin = true;
                              _qrExpanded = true;
                            }),
                            onSignup: () => setState(() {
                              _isLogin = false;
                              _qrExpanded = false;
                            }),
                          ),
                        ),
                        const SizedBox(height: 30),
                        if (_isLogin)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _LoginPanel(
                                  isPasswordMethod: _isPasswordMethod,
                                  otpSent: _otpSent,
                                  otpResendSeconds: _otpResendSeconds,
                                  obscurePassword: _obscurePassword,
                                  isLoading: isLoading,
                                  usernameController: _loginUsername,
                                  passwordController: _loginPassword,
                                  phoneController: _otpPhone,
                                  otpControllers: _otpDigits,
                                  otpFocusNodes: _otpFocus,
                                  onSelectPassword: () => setState(() {
                                    _isPasswordMethod = true;
                                    _otpSent = false;
                                    _otpPhoneNormalized = '';
                                    _clearOtpDigits();
                                  }),
                                  onSelectOtp: () => setState(() {
                                    _isPasswordMethod = false;
                                  }),
                                  onToggleObscure: () => setState(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  ),
                                  onSendOtp: _submitSendOtp,
                                  onVerifyOtp: _submitVerifyOtp,
                                  onLogin: _submitLogin,
                                  onGoogle: _signInWithGoogle,
                                ),
                              ),
                              const SizedBox(width: 22),
                              _QrPanel(
                                expanded: _qrExpanded,
                                link: _qrLink,
                                onExpand: () =>
                                    setState(() => _qrExpanded = true),
                                onCollapse: () =>
                                    setState(() => _qrExpanded = false),
                                onRefresh: _refreshQr,
                              ),
                            ],
                          )
                        else
                          _SignupPanel(
                            agreeTerms: _agreeTerms,
                            obscurePassword: _obscureSignupPassword,
                            usernameController: _signupUsername,
                            emailController: _signupEmail,
                            passwordController: _signupPassword,
                            phoneController: _signupPhone,
                            onToggleTerms: () =>
                                setState(() => _agreeTerms = !_agreeTerms),
                            onToggleObscure: () => setState(
                              () => _obscureSignupPassword =
                                  !_obscureSignupPassword,
                            ),
                            onLoginTap: () => setState(() {
                              _isLogin = true;
                              _qrExpanded = true;
                            }),
                            onGoogle: _signInWithGoogle,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: _CloseButton(onTap: _goBack),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/img/logo_large.png',
          width: 400,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        const Text(
          'به بامابین خوش آمدید',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'فیلم و سریال، هر جا هر وقت',
          style: TextStyle(fontSize: 13.5, color: _authMuted),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(Icons.close, size: 16, color: _authLabel),
        ),
      ),
    );
  }
}

class _TabPills extends StatelessWidget {
  const _TabPills({
    required this.isLogin,
    required this.onLogin,
    required this.onSignup,
  });

  final bool isLogin;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Pill(label: 'ورود', active: isLogin, onTap: onLogin),
        const SizedBox(width: 8),
        _Pill(label: 'ثبت‌نام', active: !isLogin, onTap: onSignup),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: active
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [blueColor, desktopAccentDarkColor],
                  )
                : null,
            color: active ? null : _authSurface,
            border: active
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFFC7C9D9),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.isPasswordMethod,
    required this.otpSent,
    required this.otpResendSeconds,
    required this.obscurePassword,
    required this.isLoading,
    required this.usernameController,
    required this.passwordController,
    required this.phoneController,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.onSelectPassword,
    required this.onSelectOtp,
    required this.onToggleObscure,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onLogin,
    required this.onGoogle,
  });

  final bool isPasswordMethod;
  final bool otpSent;
  final int otpResendSeconds;
  final bool obscurePassword;
  final bool isLoading;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final VoidCallback onSelectPassword;
  final VoidCallback onSelectOtp;
  final VoidCallback onToggleObscure;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onLogin;
  final VoidCallback onGoogle;

  bool get _canSendOtp => !isLoading && otpResendSeconds <= 0;

  String get _resendLabel {
    if (otpResendSeconds <= 0) return 'ارسال دوباره کد';
    final minutes = (otpResendSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (otpResendSeconds % 60).toString().padLeft(2, '0');
    return 'ارسال دوباره کد ($minutes:$seconds)';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MethodTabs(
          isPassword: isPasswordMethod,
          onPassword: onSelectPassword,
          onOtp: onSelectOtp,
        ),
        const SizedBox(height: 22),
        if (isPasswordMethod) ...[
          _FieldLabel('نام کاربری'),
          _AuthField(
            controller: usernameController,
            hint: 'نام کاربری خود را وارد کنید',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _FieldLabel('رمز عبور'),
          _AuthField(
            controller: passwordController,
            hint: 'رمز عبور خود را وارد کنید',
            obscure: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) onLogin();
            },
            suffix: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: _authSubtle,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: blueColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontFamily: 'dana',
                  fontSize: 13,
                ),
              ),
              child: const Text('فراموشی رمز عبور؟'),
            ),
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'ورود',
            enabled: !isLoading,
            onTap: onLogin,
          ),
        ] else ...[
          _FieldLabel('شماره موبایل'),
          Row(
            children: [
              Expanded(
                child: _AuthField(
                  controller: phoneController,
                  hint: '۰۹۱۲۳۴۵۶۷۸۹',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (_canSendOtp) onSendOtp();
                  },
                ),
              ),
              const SizedBox(width: 8),
              _SecondaryButton(
                label: 'دریافت کد',
                onTap: _canSendOtp ? onSendOtp : () {},
              ),
            ],
          ),
          if (otpSent) ...[
            const SizedBox(height: 16),
            _FieldLabel('کد تایید'),
            _OtpBoxes(
              controllers: otpControllers,
              focusNodes: otpFocusNodes,
              onCompleted: () {
                if (!isLoading) onVerifyOtp();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'کد را دریافت نکردید؟',
                  style: TextStyle(fontSize: 12.5, color: _authMuted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _canSendOtp ? onSendOtp : null,
                  style: TextButton.styleFrom(
                    foregroundColor: blueColor,
                    disabledForegroundColor: _authSubtle,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: 'dana',
                      fontSize: 12.5,
                    ),
                  ),
                  child: Text(_resendLabel),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PrimaryButton(
              label: 'ورود',
              enabled: !isLoading,
              onTap: onVerifyOtp,
            ),
          ],
        ],
        const _OrDivider(label: 'یا ورود با'),
        _SocialButtons(onGoogle: onGoogle),
      ],
    );
  }
}

class _SignupPanel extends StatelessWidget {
  const _SignupPanel({
    required this.agreeTerms,
    required this.obscurePassword,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.phoneController,
    required this.onToggleTerms,
    required this.onToggleObscure,
    required this.onLoginTap,
    required this.onGoogle,
  });

  final bool agreeTerms;
  final bool obscurePassword;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController phoneController;
  final VoidCallback onToggleTerms;
  final VoidCallback onToggleObscure;
  final VoidCallback onLoginTap;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('نام کاربری'),
        _AuthField(
          controller: usernameController,
          hint: 'یک نام کاربری انتخاب کنید',
        ),
        const SizedBox(height: 16),
        _FieldLabel('ایمیل'),
        _AuthField(
          controller: emailController,
          hint: 'example@email.com',
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 16),
        _FieldLabel('رمز عبور'),
        _AuthField(
          controller: passwordController,
          hint: 'حداقل ۸ کاراکتر',
          obscure: obscurePassword,
          suffix: IconButton(
            onPressed: onToggleObscure,
            icon: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: _authSubtle,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel.rich(
          children: const [
            TextSpan(text: 'شماره موبایل '),
            TextSpan(
              text: '(اختیاری)',
              style: TextStyle(color: _authSubtle),
            ),
          ],
        ),
        _AuthField(
          controller: phoneController,
          hint: '۰۹۱۲۳۴۵۶۷۸۹',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: onToggleTerms,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: agreeTerms
                      ? LinearGradient(
                          colors: [blueColor, desktopAccentDarkColor],
                        )
                      : null,
                  border: agreeTerms
                      ? null
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                ),
                child: agreeTerms
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: _authLabel,
                      height: 1.7,
                    ),
                    children: [
                      const TextSpan(
                        text: 'قوانین و مقررات و ',
                      ),
                      TextSpan(
                        text: 'حریم خصوصی',
                        style: TextStyle(
                          color: blueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' بامابین را می‌پذیرم'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'ایجاد حساب کاربری',
          enabled: agreeTerms,
          onTap: () {},
        ),
        const _OrDivider(label: 'یا ثبت‌نام با'),
        _SocialButtons(onGoogle: onGoogle),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'قبلاً حساب کاربری ساخته‌اید؟ ',
              style: TextStyle(fontSize: 13.5, color: _authMuted),
            ),
            TextButton(
              onPressed: onLoginTap,
              style: TextButton.styleFrom(
                foregroundColor: blueColor,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontFamily: 'dana',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('ورود'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MethodTabs extends StatelessWidget {
  const _MethodTabs({
    required this.isPassword,
    required this.onPassword,
    required this.onOtp,
  });

  final bool isPassword;
  final VoidCallback onPassword;
  final VoidCallback onOtp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _authSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodChip(
              label: 'نام کاربری و رمز عبور',
              active: isPassword,
              onTap: onPassword,
            ),
          ),
          Expanded(
            child: _MethodChip(
              label: 'موبایل و کد تایید',
              active: !isPassword,
              onTap: onOtp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 38,
          decoration: BoxDecoration(
            color: active ? _authField : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? _authInk : const Color(0xFF8B8DA0),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text) : children = null;

  const _FieldLabel.rich({required this.children}) : text = null;

  final String? text;
  final List<InlineSpan>? children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: text != null
          ? Text(
              text!,
              style: const TextStyle(fontSize: 13.5, color: _authMuted),
            )
          : Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13.5, color: _authMuted),
                children: children,
              ),
            ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textDirection,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textDirection: textDirection,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(fontSize: 14.5, color: _authInk),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14.5,
            color: _authSubtle.withValues(alpha: 0.85),
          ),
          filled: true,
          fillColor: _authField,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: blueColor.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.controllers,
    required this.focusNodes,
    this.onCompleted,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    final count = controllers.length;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: List.generate(count, (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == count - 1 ? 0 : 6,
              ),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: controllers[index],
                  focusNode: focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _authInk,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: _authField,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: blueColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < count - 1) {
                      focusNodes[index + 1].requestFocus();
                    } else if (value.isEmpty && index > 0) {
                      focusNodes[index - 1].requestFocus();
                    }

                    if (controllers.every((c) => c.text.isNotEmpty)) {
                      onCompleted?.call();
                    }
                  },
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [blueColor, desktopAccentDarkColor],
                    )
                  : null,
              color: enabled ? null : const Color(0xFF3A3550),
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: blueColor.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: blueColor.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _authSubtle),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.onGoogle});

  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return _SocialButton(
      label: 'گوگل',
      onTap: onGoogle,
      leading: const _GoogleIcon(),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    required this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _authSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              leading,
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE8E9F2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFFEA4335),
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: _authSurface,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel({
    required this.expanded,
    required this.link,
    required this.onExpand,
    required this.onCollapse,
    required this.onRefresh,
  });

  final bool expanded;
  final String? link;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 280 : 150,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: blueColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: blueColor.withValues(alpha: expanded ? 0.3 : 0.4),
        ),
      ),
      child: expanded
          ? _QrExpanded(
              link: link,
              onCollapse: onCollapse,
              onRefresh: onRefresh,
            )
          : _QrCollapsed(onExpand: onExpand),
    );
  }
}

class _QrCollapsed extends StatelessWidget {
  const _QrCollapsed({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onExpand,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _authField,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.qr_code_2, size: 26, color: blueColor),
            ),
            const SizedBox(height: 14),
            const Text(
              'ورود آسان',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'با اسکن کد QR وارد شوید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: _authMuted,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrExpanded extends StatelessWidget {
  const _QrExpanded({
    required this.link,
    required this.onCollapse,
    required this.onRefresh,
  });

  final String? link;
  final VoidCallback onCollapse;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final hasLink = link != null && link!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ورود آسان',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            InkWell(
              onTap: onCollapse,
              borderRadius: BorderRadius.circular(6),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.close, size: 14, color: Color(0xFF8B8DA0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasLink)
          const SizedBox(
            height: 220,
            child: Center(
              child: LoadingWidget(showText: false),
            ),
          )
        else ...[
          Container(
            width: 180,
            height: 180,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: link!,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'با دوربین گوشی هوشمند خود این کد را اسکن کنید یا لینک زیر را در مرورگر باز نمایید.\n\n'
            'اگر اپلیکیشن بامابین را ندارید می‌توانید لینک را کپی کرده و در مرورگر باز کنید. نیازی به نصب اپلیکیشن نیست.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              height: 1.7,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            link!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'vazir',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: _authLabel,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              textStyle: const TextStyle(
                fontFamily: 'dana',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('دریافت کد جدید'),
          ),
        ],
      ],
    );
  }
}
