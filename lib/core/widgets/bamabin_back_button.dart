import 'package:bamabin_desktop/core/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class BamabinBackButton extends StatelessWidget {
  const BamabinBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'بازگشت',
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        color: Colors.black.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          canRequestFocus: false,
          onTap: () => _handleTap(context),
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SvgPicture.asset(
                'assets/img/arrow_left.svg',
                width: 16,
                height: 16,
                matchTextDirection: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
