import 'dart:ui';

import 'package:flutter/material.dart';

Future<bool> showShelfDeleteConfirmDialog(
  BuildContext context, {
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xBF131321),
    builder: (dialogContext) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: 434,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xBF131321),
                      Color(0xFF0C0C14),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'vazir',
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogButton(
                            label: 'پاکش کن',
                            background: const Color(0xFFEF4444),
                            borderColor: Colors.white.withValues(alpha: 0.09),
                            foreground: Colors.white,
                            onTap: () => Navigator.of(dialogContext).pop(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DialogButton(
                            label: 'نه ولش کن!',
                            background: Colors.white.withValues(alpha: 0.09),
                            borderColor: Colors.white.withValues(alpha: 0.2),
                            foreground: Colors.white.withValues(alpha: 0.75),
                            onTap: () =>
                                Navigator.of(dialogContext).pop(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  return result == true;
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.borderColor,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color borderColor;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'vazir',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.18,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}
