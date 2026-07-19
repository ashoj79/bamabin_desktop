import 'package:bamabin_desktop/config/theme.dart';
import 'package:bamabin_desktop/core/router.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/utils/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await setupLocator();
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
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              color: themeData.colorScheme.surface,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
