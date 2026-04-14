import 'dart:math';
import 'package:flutter/material.dart';
import 'package:crisissync/config/theme.dart';

/// ADI Score circular gauge widget.
class ADIScoreGauge extends StatelessWidget {
  final double score;
  final double size;

  const ADIScoreGauge({super.key, required this.score, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.adiColor(score);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ADIGaugePainter(score: score, color: color),
        child: Center(
          child: Text(
            score.toInt().toString(),
            style: AppTextStyles.jetBrainsMono(
              fontSize: size * 0.28,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _ADIGaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _ADIGaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.borderDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Score arc
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * pi * 1.5;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      scorePaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ADIGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
