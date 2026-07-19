import 'package:bamabin_desktop/config/color.dart';
import 'package:flutter/material.dart';

class QuestionAlert extends StatelessWidget {
  const QuestionAlert({
    super.key,
    required this.message,
    required this.onClick,
  });

  final String message;
  final ValueChanged<bool> onClick;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: const Color(0xFF2B2B2B),
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onClick(false),
                    child: const Text(
                      'خیر',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => onClick(true),
                    child: Text(
                      'بله',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: redColor,
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

void showQuestionAlert(
  BuildContext context,
  String message,
  ValueChanged<bool> onClick,
) {
  showDialog(
    context: context,
    builder: (context) => QuestionAlert(message: message, onClick: onClick),
  );
}
