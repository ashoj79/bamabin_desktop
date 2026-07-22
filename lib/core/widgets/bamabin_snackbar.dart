import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> bamabinScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showBamabinSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(_buildSnackBar(message));
}

void showBamabinSnackbarMessage(String message) {
  final messenger = bamabinScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(_buildSnackBar(message));
}

SnackBar _buildSnackBar(String message) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.black.withValues(alpha: 0.7),
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    padding: EdgeInsets.zero,
    content: Directionality(
      textDirection: TextDirection.rtl,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0, maxHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 3,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: yellowColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.warning, color: yellowColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  message.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
