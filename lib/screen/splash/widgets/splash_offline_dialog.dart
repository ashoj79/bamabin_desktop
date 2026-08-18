import 'package:bamabin_desktop/config/color.dart';
import 'package:bamabin_desktop/core/routes.dart';
import 'package:bamabin_desktop/data/local/temp_db.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SplashOfflineDialog extends StatelessWidget {
  const SplashOfflineDialog({super.key});

  Future<void> _openSupport() async {
    final url = TempDb.supportLink.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 455,
          padding: const EdgeInsets.all(33),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF131321).withValues(alpha: 0.75),
                const Color(0xFF0C0C14),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/img/download/ic_cloud_offline.svg',
                width: 110,
                height: 110,
              ),
              const SizedBox(height: 16),
              const Text(
                'شما آفلاین هستید!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'dana',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 16.1 / 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'میتوانید محتوای از قبل دانلود شده را تماشا\nیا برای رفع مشکل با پشتیبانی در ارتباط باشید!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'vazir',
                  fontSize: 15,
                  height: 26 / 15,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: _openSupport,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.48),
                            ),
                          ),
                          child: Text(
                            'ارتباط با پشتیبانی',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.18,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      color: blueColor,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => context.go(Routes.downloadManager),
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Text(
                            'دانلود ها',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'vazir',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.18,
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
      ),
    );
  }
}
