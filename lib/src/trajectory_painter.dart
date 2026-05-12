import 'dart:math' as math;
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
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    // Create longer dotted effect with clearer visibility
    final dashPath = _createDashedPath(path, 16.0, 8.0);

    final shader = LinearGradient(
      begin: Alignment(start.dx / math.max(size.width, 1.0),
          start.dy / math.max(size.height, 1.0)),
      end: Alignment(end.dx / math.max(size.width, 1.0),
          end.dy / math.max(size.height, 1.0)),
      colors: [Colors.blue.shade700, Colors.blue.shade200, Colors.transparent],
      stops: const [0.0, 0.6, 1.0],
    ).createShader(Rect.fromPoints(start, end));

    paint.shader = shader;
    canvas.drawPath(dashPath, paint);

    final dotPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.75);
    for (double t = 0.0; t <= 1.0; t += 0.2) {
      final point = Offset(
        start.dx + (end.dx - start.dx) * t,
        start.dy + (end.dy - start.dy) * t,
      );
      canvas.drawCircle(point, 6.0, dotPaint);
    }
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
