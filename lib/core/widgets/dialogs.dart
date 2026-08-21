import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/widgets/loading_widget.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _openUrl(String url) async {
  if (url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

ButtonStyle _dialogButtonStyle(BuildContext context) {
  final primary = Theme.of(context).colorScheme.primary;
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return primary;
      }
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return Colors.white;
      }
      return Colors.black;
    }),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    minimumSize: WidgetStateProperty.all(const Size(double.infinity, 48)),
  );
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    this.title = 'مشکلی پیش آمده',
    required this.message,
    this.showTelegramChannel = true,
    this.showSecondBtn = true,
    this.firstBtnText = 'تلاش مجدد',
    this.secondBtnText = 'ارتباط با پشتیبانی',
    required this.onCloseClick,
    required this.onRetryClick,
    this.onSecondBtnClicked,
  });

  final String title;
  final String message;
  final bool showTelegramChannel;
  final bool showSecondBtn;
  final String firstBtnText;
  final String secondBtnText;
  final VoidCallback onCloseClick;
  final VoidCallback onRetryClick;
  final VoidCallback? onSecondBtnClicked;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );
    final buttonTextStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: const Color(0xFF2B2B2B),
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    title,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: IconButton(
                    onPressed: onCloseClick,
                    icon: Icon(Icons.cancel_outlined, color: failedColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(message, style: bodyStyle, textAlign: TextAlign.center),
            const SizedBox(height: 48),
            ElevatedButton(
              style: _dialogButtonStyle(context),
              onPressed: onRetryClick,
              child: Text(
                firstBtnText,
                textAlign: TextAlign.center,
                style: buttonTextStyle,
              ),
            ),
            if (showSecondBtn) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                style: _dialogButtonStyle(context),
                onPressed: () {
                  if (onSecondBtnClicked != null) {
                    onSecondBtnClicked!();
                  } else {
                    _openUrl(TempDb.supportLink);
                  }
                },
                child: Text(
                  secondBtnText,
                  textAlign: TextAlign.center,
                  style: buttonTextStyle,
                ),
              ),
            ],
            if (showTelegramChannel) ...[
              const SizedBox(height: 16),
              Text(
                'در صورت بروز مشکل با پشتیبانی تلگرام در ارتباط باشید',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  '@Bamabin_Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2B2B2B),
      content: const SizedBox(
        width: 300,
        height: 300,
        child: LoadingWidget(),
      ),
    );
  }
}

Future<void> showErrorDialog(
  BuildContext context, {
  String title = 'مشکلی پیش آمده',
  required String message,
  bool showTelegramChannel = true,
  bool showSecondBtn = true,
  String firstBtnText = 'تلاش مجدد',
  String secondBtnText = 'ارتباط با پشتیبانی',
  required VoidCallback onCloseClick,
  required VoidCallback onRetryClick,
  VoidCallback? onSecondBtnClicked,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => ErrorDialog(
      title: title,
      message: message,
      showTelegramChannel: showTelegramChannel,
      showSecondBtn: showSecondBtn,
      firstBtnText: firstBtnText,
      secondBtnText: secondBtnText,
      onCloseClick: () {
        Navigator.of(context).pop();
        onCloseClick();
      },
      onRetryClick: () {
        Navigator.of(context).pop();
        onRetryClick();
      },
      onSecondBtnClicked: onSecondBtnClicked == null
          ? null
          : () {
              Navigator.of(context).pop();
              onSecondBtnClicked();
            },
    ),
  );
}

Future<void> showLoadingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LoadingDialog(),
  );
}
