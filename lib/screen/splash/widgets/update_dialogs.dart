import 'dart:io';

import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/data/remote/model/app/app_version.dart';
import 'package:bamabin_desktop/screen/splash/bloc/splash_bloc.dart';
import 'package:bamabin_desktop/utils/app_update_helper.dart';
import 'package:flutter/material.dart';

const _updateOverlay = Color(0xCC0D0D0D);
const _updateTitle = Color(0xFFF5EFE6);
const _updateBorder = Color(0x0FFFFFFF);
const _progressTrack = Color(0xFF2E2E2E);

class SplashUpdateOverlay extends StatelessWidget {
  const SplashUpdateOverlay({
    super.key,
    required this.appVersion,
    required this.downloadState,
    required this.onUpdateClick,
    required this.onDismissClick,
  });

  final AppVersion appVersion;
  final UpdateDownloadState downloadState;
  final VoidCallback onUpdateClick;
  final VoidCallback onDismissClick;

  @override
  Widget build(BuildContext context) {
    return switch (downloadState) {
      UpdateDownloadDownloading(
        :final downloadedBytes,
        :final totalBytes,
      ) =>
        UpdateProgressDialog(
          appVersion: appVersion,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
          percent: totalBytes > 0
              ? ((downloadedBytes * 100) ~/ totalBytes).clamp(0, 100)
              : 0,
        ),
      UpdateDownloadReady(:final filePath) => UpdateProgressDialog(
        appVersion: appVersion,
        downloadedBytes: _fileLength(filePath),
        totalBytes: _fileLength(filePath),
        percent: 100,
      ),
      _ => UpdateAlertDialog(
        appVersion: appVersion,
        onUpdateClick: onUpdateClick,
        onDismissClick: onDismissClick,
      ),
    };
  }

  static int _fileLength(String path) {
    try {
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }
}

class UpdateAlertDialog extends StatelessWidget {
  const UpdateAlertDialog({
    super.key,
    required this.appVersion,
    required this.onUpdateClick,
    required this.onDismissClick,
  });

  final AppVersion appVersion;
  final VoidCallback onUpdateClick;
  final VoidCallback onDismissClick;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _updateOverlay,
      child: Center(
        child: _UpdateDialogCard(
          children: [
            const _UpdateDialogHeaderTitle(),
            _UpdateDialogHeaderBody(appVersion: appVersion),
            if (appVersion.description.trim().isNotEmpty)
              Text(
                appVersion.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            if (appVersion.isRequires)
              Text(
                'این بروز رسانی اجباریست.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            if (appVersion.isRequires)
              _UpdatePrimaryButton(
                text: 'بروزرسانی',
                onClick: onUpdateClick,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _UpdatePrimaryButton(
                      text: 'بروزرسانی',
                      onClick: onUpdateClick,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: onDismissClick,
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        height: 38,
                        child: Center(
                          child: Text(
                            'بی خیالش!',
                            style: TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class UpdateProgressDialog extends StatelessWidget {
  const UpdateProgressDialog({
    super.key,
    required this.appVersion,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.percent,
  });

  final AppVersion appVersion;
  final int downloadedBytes;
  final int totalBytes;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final fraction = totalBytes > 0
        ? (downloadedBytes / totalBytes).clamp(0.0, 1.0)
        : 0.0;
    final sizeLabel = totalBytes > 0
        ? '$percent% (${AppUpdateHelper.formatBytes(downloadedBytes)} از ${AppUpdateHelper.formatBytes(totalBytes)})'
        : AppUpdateHelper.formatBytes(downloadedBytes);

    return ColoredBox(
      color: _updateOverlay,
      child: Center(
        child: _UpdateDialogCard(
          children: [
            const _UpdateDialogHeaderTitle(),
            _UpdateDialogHeaderBody(appVersion: appVersion),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 4,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: _progressTrack),
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: fraction < 0.02 && downloadedBytes > 0
                          ? 0.02
                          : fraction,
                      child: ColoredBox(color: blueColor),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    sizeLabel,
                    style: const TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'درحال دانلود ...',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'vazir',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const _UpdatePrimaryButton(
              text: 'درحال دانلود',
              onClick: null,
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateDialogCard extends StatelessWidget {
  const _UpdateDialogCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _updateBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: blueColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: blueColor.withValues(alpha: 0.3),
                  blurRadius: 11,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          ..._withSpacing(children, 12),
        ],
      ),
    );
  }

  List<Widget> _withSpacing(List<Widget> items, double gap) {
    if (items.isEmpty) return items;
    final result = <Widget>[items.first];
    for (var i = 1; i < items.length; i++) {
      result.add(SizedBox(height: gap));
      result.add(items[i]);
    }
    return result;
  }
}

class _UpdateDialogHeaderTitle extends StatelessWidget {
  const _UpdateDialogHeaderTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'بروزرسانی اپلیکیشن',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'dana',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _updateTitle,
      ),
    );
  }
}

class _UpdateDialogHeaderBody extends StatelessWidget {
  const _UpdateDialogHeaderBody({required this.appVersion});

  final AppVersion appVersion;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = TextStyle(
      fontFamily: 'vazir',
      fontSize: 14,
      color: Colors.white.withValues(alpha: 0.6),
    );

    return Column(
      children: [
        Text(
          'نسخه جدید اپلیکیشن آماده است.',
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
        if (appVersion.versionName.trim().isNotEmpty)
          Text(
            'نسخه: ${appVersion.versionName}',
            textAlign: TextAlign.center,
            style: bodyStyle,
          ),
      ],
    );
  }
}

class _UpdatePrimaryButton extends StatelessWidget {
  const _UpdatePrimaryButton({
    required this.text,
    required this.onClick,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onClick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: blueColor.withValues(alpha: enabled ? 1 : 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onClick : null,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 38,
          width: double.infinity,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'vazir',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
