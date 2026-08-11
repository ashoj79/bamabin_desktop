import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BamabinEmptyState extends StatelessWidget {
  const BamabinEmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/img/download_empty_smiley.svg',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 24 / 20,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
