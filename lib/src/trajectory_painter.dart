import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TrajectoryPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double fadeDistance;

  TrajectoryPainter({
    required this.start,
    required this.end,
    this.fadeDistance = 100.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    // Create longer dotted effect
    final dashPath = _createDashedPath(path, 10.0, 5.0);

    // Apply fading
    final shader = LinearGradient(
      begin: Alignment(start.dx / size.width, start.dy / size.height),
      end: Alignment(end.dx / size.width, end.dy / size.height),
      colors: [Colors.blue, Colors.transparent],
      stops: [0.0, 1.0],
    ).createShader(Rect.fromPoints(start, end));

    paint.shader = shader;

    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final Path dashedPath = Path();
    final ui.PathMetrics pathMetrics = source.computeMetrics();
    for (final ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final double length = draw ? dashLength : gapLength;
        if (draw) {
          final ui.Tangent? tangent = pathMetric.getTangentForOffset(distance);
          if (tangent != null) {
            dashedPath.addPath(
              Path()
                ..moveTo(tangent.position.dx, tangent.position.dy)
                ..lineTo(
                  tangent.position.dx + tangent.vector.dx * dashLength,
                  tangent.position.dy + tangent.vector.dy * dashLength,
                ),
              Offset.zero,
            );
          }
        }
        distance += length;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
