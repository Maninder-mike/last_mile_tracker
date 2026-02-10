import 'dart:math';
import 'package:flutter/cupertino.dart';

class Speedometer extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final double size;

  const Speedometer({
    super.key,
    required this.speed,
    this.maxSpeed = 120.0,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SpeedometerPainter(
          speed: speed,
          maxSpeed: maxSpeed,
          color: CupertinoTheme.of(context).primaryColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              Text(
                'km/h',
                style: TextStyle(
                  fontSize: size * 0.08,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final Color color;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.1;

    // Background Arc
    final bgPaint = Paint()
      ..color = CupertinoColors.systemGrey5
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = 135 * pi / 180;
    const sweepAngle = 270 * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Speed Arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressSweep = (speed / maxSpeed).clamp(0.0, 1.0) * sweepAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.color != color;
  }
}
