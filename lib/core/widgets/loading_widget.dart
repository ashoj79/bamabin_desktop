import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.showText = true});

  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(10),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            'در حال دریافت اطلاعات',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
