import 'package:flutter/material.dart';

class StrokeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double strokeWidth;
  final Color strokeColor;
  final TextAlign textAlign;
  final TextScaler textScaler;
  const StrokeText({
    super.key,
    required this.text,
    this.style,
    this.strokeWidth = 1,
    this.strokeColor = Colors.black,
    this.textAlign = TextAlign.center,
    this.textScaler = const TextScaler.linear(1),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outline
        ExcludeSemantics(
          child: Text(
            text,
            style: (style ?? const TextStyle()).copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..color = strokeColor,
            ),
            textAlign: textAlign,
            textScaler: textScaler,
          ),
        ),
        // Solid text inside
        Text(
          text,
          style: style,
          textAlign: textAlign,
          textScaler: textScaler,
        ),
      ],
    );
  }
}
