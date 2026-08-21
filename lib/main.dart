import 'package:bamabin_desktop/config/theme.dart';
import 'package:bamabin_desktop/core/router.dart';
import 'package:bamabin_desktop/core/window_chrome.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/core/widgets/window_title_bar.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/utils/deep_link_handler.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:bamabin_desktop/utils/download_completion_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDesktopWindow();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  var _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureDesktopWindowVisible();
      _start();
    });
  }

  Future<void> _start() async {
    try {
      MediaKit.ensureInitialized();
      await setupLocator();
      await DownloadCompletionNotifier.instance.init();
      await DeepLinkHandler.instance.init();
      if (!mounted) return;
      setState(() => _ready = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureDesktopWindowVisible();
      });
    } catch (e, st) {
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        home: Scaffold(
          backgroundColor: const Color(0xFF121216),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'خطا در اجرای برنامه:\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: themeData,
        home: const Scaffold(
          backgroundColor: Color(0xFF121216),
          body: Center(child: LoadingWidget(showText: false)),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashBloc>(create: (context) => locator()),
      ],
      child: const BamabinApp(),
    );
  }
}

class BamabinApp extends StatefulWidget {
  const BamabinApp({super.key});

  @override
  State<BamabinApp> createState() => _BamabinAppState();
}

class _BamabinAppState extends State<BamabinApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureDesktopWindowVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bamabin',
      theme: themeData,
      darkTheme: themeData,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: bamabinScaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Overlay.wrap(
              child: Scaffold(
                backgroundColor: themeData.colorScheme.surface,
                body: Column(
                  children: [
                    const WindowTitleBar(),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
