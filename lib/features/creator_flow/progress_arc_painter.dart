import 'dart:math';
import 'package:flutter/material.dart';

class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  ProgressArcPainter({required this.progress, required this.color});

  @override 
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = color 
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }

}