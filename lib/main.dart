import 'package:bamabin_desktop/config/theme.dart';
import 'package:bamabin_desktop/core/router.dart';
import 'package:bamabin_desktop/core/window_chrome.dart';
import 'package:bamabin_desktop/core/widgets/bamabin_snackbar.dart';
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
  MediaKit.ensureInitialized();
  await setupLocator();
  await DownloadCompletionNotifier.instance.init();
  await DeepLinkHandler.instance.init();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SplashBloc>(create: (context) => locator()),
      ],
      child: const BamabinApp(),
    ),
  );
}

class BamabinApp extends StatelessWidget {
  const BamabinApp({super.key});

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
