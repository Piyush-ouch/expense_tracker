import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlowingCircularLoader extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  
  const GlowingCircularLoader({
    super.key,
    this.size = 60.0,
    this.color = const Color(0xFFFDD835), // Yellow accent
    this.strokeWidth = 4.0,
  });

  @override
  State<GlowingCircularLoader> createState() => _GlowingCircularLoaderState();
}

class _GlowingCircularLoaderState extends State<GlowingCircularLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GlowingCirclePainter(
            progress: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _GlowingCirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GlowingCirclePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw multiple layers of glow for stronger effect
    // Outer glow - very soft
    final outerGlowPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    // Middle glow - medium
    final middleGlowPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    // Inner glow - strong
    final innerGlowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Main arc - solid
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi;
    final sweepAngle = math.pi * 1.5; // 270 degrees

    // Draw all glow layers
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      outerGlowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      middleGlowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      innerGlowPaint,
    );

    // Draw main arc on top
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GlowingCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
