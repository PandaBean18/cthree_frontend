import 'package:flutter/material.dart';

class ButtonProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  ButtonProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
                  ..color = color
                  ..strokeWidth = 3
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round;

    final path = Path()
                ..addRRect(RRect.fromRectAndRadius(
                  Rect.fromLTWH(0, 0, size.width, size.height),
                  const Radius.circular(12)));

    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      final extractPath = metric.extractPath(0.0, metric.length * progress);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(ButtonProgressPainter oldDelegate) => oldDelegate.progress != progress;
}