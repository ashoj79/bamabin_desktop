import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/screen/splash/widgets/splash_offline_dialog.dart';
import 'package:bamabin_desktop/screen/splash/widgets/update_dialogs.dart';
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

  Future<void> _openInstaller(String filePath) async {
    try {
      await context.read<SplashBloc>().openInstallerAndExit(filePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      context.read<SplashBloc>().add(ResetAppUpdateDownload());
    }
  }

  void _goMain() {
    context.go(Routes.main);
    DeepLinkHandler.instance.markReady();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashSuccess) {
          final download = state.downloadState;

          if (download is UpdateDownloadReady) {
            _openInstaller(download.filePath);
            return;
          }

          if (download is UpdateDownloadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(download.message)),
            );
            context.read<SplashBloc>().add(ResetAppUpdateDownload());
            return;
          }

          if (!state.appVersion.needUpdate) {
            _goMain();
            return;
          }

          if (!_showUpdateDialog) {
            setState(() => _showUpdateDialog = true);
          }
          return;
        }

        if (state is SplashError && _showUpdateDialog) {
          setState(() => _showUpdateDialog = false);
        }
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
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/img/logo.jpg',
                    fit: BoxFit.contain,
                    width: 180,
                    height: 180,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 48),
                  child: SizedBox(
                    width: 164,
                    height: 164,
                    child: state is SplashLoading || state is SplashInitial
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
              if (state is SplashError) const SplashOfflineDialog(),
              if (_showUpdateDialog && state is SplashSuccess)
                SplashUpdateOverlay(
                  appVersion: state.appVersion,
                  downloadState: state.downloadState,
                  onUpdateClick: () {
                    context.read<SplashBloc>().add(StartAppUpdateDownload());
                  },
                  onDismissClick: () {
                    if (state.appVersion.isRequires) return;
                    setState(() => _showUpdateDialog = false);
                    context.read<SplashBloc>().add(ResetAppUpdateDownload());
                    _goMain();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
