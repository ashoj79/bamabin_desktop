import 'dart:io';

import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/dialogs.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/utils/deep_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  var _showUpdateDialog = false;
  Future<String>? _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = PackageInfo.fromPlatform().then((info) => info.version);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SplashBloc>().add(GetStartupData());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is! SplashSuccess) return;

        if (!state.appVersion.needUpdate) {
          context.go(Routes.main);
          DeepLinkHandler.instance.markReady();
          return;
        }

        setState(() => _showUpdateDialog = true);
      },
      builder: (context, state) {
        return ColoredBox(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Image.asset(
                  'assets/img/logo_dark.png',
                  fit: BoxFit.contain,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 164,
                    height: 164,
                    child: state is SplashLoading
                        ? const LoadingWidget(showText: false)
                        : null,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FutureBuilder<String>(
                    future: _versionFuture,
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (state is SplashError)
                ErrorDialog(
                  message: state.message,
                  onCloseClick: () => exit(0),
                  onRetryClick: () {
                    context.read<SplashBloc>().add(GetStartupData());
                  },
                ),
              if (_showUpdateDialog && state is SplashSuccess)
                UpdateDialog(appVersion: state.appVersion),
            ],
          ),
        );
      },
    );
  }
}
