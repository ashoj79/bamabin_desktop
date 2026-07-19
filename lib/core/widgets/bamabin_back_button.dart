import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BamabinBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const BamabinBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.pop(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xB3282016),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appHairline2Color),
        ),
        child: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
