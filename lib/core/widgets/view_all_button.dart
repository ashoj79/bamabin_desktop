import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ViewAllButton extends StatelessWidget {
  const ViewAllButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: desktopInkColor,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.ltr,
          children: [
            SvgPicture.asset(
              'assets/img/arrow_left.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'مشاهده همه',
              style: TextStyle(
                fontFamily: 'dana',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                // height: 22 / 16,
                letterSpacing: -0.18,
                color: desktopInkColor,
              ),
            ),
          ],
        ),
      );
  }
}
