import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:bamabin_desktop/repository/user_repository.dart';
import 'package:bamabin_desktop/utils/deep_link_windows_stub.dart'
    if (dart.library.io) 'package:bamabin_desktop/utils/deep_link_windows.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter/foundation.dart';

class DeepLinkHandler {
  DeepLinkHandler._();

  static final DeepLinkHandler instance = DeepLinkHandler._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  var _pendingPaymentVerify = false;
  var _ready = false;
  var _processing = false;
  var _listeningLogin = false;

  Future<void> init() async {
    await _registerScheme();

    if (!_listeningLogin) {
      _listeningLogin = true;
      TempDb.isLoggedIn.addListener(_onLoginChanged);
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
    } catch (error, stack) {
      debugPrint('DeepLink initial error: $error\n$stack');
    }

    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object error, StackTrace stack) {
        debugPrint('DeepLink stream error: $error\n$stack');
      },
    );
  }

  void markReady() {
    _ready = true;
    unawaited(processPending());
  }

  void _onLoginChanged() {
    if (TempDb.isLoggedIn.value) {
      unawaited(processPending());
    }
  }

  void _handleUri(Uri uri) {
    if (!_isPaymentVerify(uri)) return;
    _pendingPaymentVerify = true;
    unawaited(processPending());
  }

  bool _isPaymentVerify(Uri uri) {
    if (uri.scheme.toLowerCase() != 'bamabin') return false;

    final host = uri.host.toLowerCase();
    if (host == 'payment.verify') return true;
    if (host == 'payment' &&
        uri.pathSegments.any((s) => s.toLowerCase() == 'verify')) {
      return true;
    }

    final path = uri.path.toLowerCase();
    return path == '/payment.verify' ||
        path.endsWith('payment.verify') ||
        path.contains('payment/verify');
  }

  Future<void> processPending() async {
    if (!_pendingPaymentVerify || !_ready || _processing) return;
    if (!TempDb.isLoggedIn.value) return;

    _processing = true;
    _pendingPaymentVerify = false;

    try {
      final ok = await locator<UserRepository>().refreshUserData();
      final vip = TempDb.vipInfo.value;

      final String message;
      if (!ok) {
        message = 'خطا در دریافت اطلاعات اشتراک';
      } else if (vip.isVip) {
        message = vip.days > 0
            ? 'اشتراک شما با موفقیت فعال شد · ${vip.days} روز باقی‌مانده'
            : 'اشتراک شما با موفقیت فعال شد';
      } else {
        message =
            'پرداخت ثبت شد؛ وضعیت اشتراک هنوز به‌روز نشده است. کمی بعد دوباره بررسی کنید';
      }

      showBamabinSnackbarMessage(message);
    } finally {
      _processing = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    if (_listeningLogin) {
      TempDb.isLoggedIn.removeListener(_onLoginChanged);
      _listeningLogin = false;
    }
  }

  Future<void> _registerScheme() async {
    if (kIsWeb) return;
    try {
      if (Platform.isWindows) {
        await registerBamabinWindowsProtocol();
      } else if (Platform.isLinux) {
        await _registerLinuxScheme();
      }
    } catch (error, stack) {
      debugPrint('DeepLink register error: $error\n$stack');
    }
  }

  Future<void> _registerLinuxScheme() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return;

    final appsDir = Directory('$home/.local/share/applications');
    await appsDir.create(recursive: true);

    final exe = Platform.resolvedExecutable;
    const desktopName = 'com.example.bamabin_desktop.desktop';
    final desktopFile = File('${appsDir.path}/$desktopName');
    await desktopFile.writeAsString('''
[Desktop Entry]
Name=Bamabin
Exec="$exe" %u
Type=Application
Terminal=false
Categories=AudioVideo;Player;
MimeType=x-scheme-handler/bamabin;
''');

    await Process.run('update-desktop-database', [appsDir.path]);
    await Process.run('xdg-mime', [
      'default',
      desktopName,
      'x-scheme-handler/bamabin',
    ]);
  }
}
