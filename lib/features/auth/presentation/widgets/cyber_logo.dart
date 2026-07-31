import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CyberLogo extends StatefulWidget {
  final double size;

  const CyberLogo({super.key, this.size = 80});

  @override
  State<CyberLogo> createState() => _CyberLogoState();
}

class _CyberLogoState extends State<CyberLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: AppColors.secondary.withOpacity(_glowAnimation.value * 0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _HexLogoaPainter(
              glowIntensity: _glowAnimation.value,
            ),
            size: Size(widget.size, widget.size),
          ),
        );
      },
    );
  }
}

class _HexLogoaPainter extends CustomPainter {
  final double glowIntensity;

  _HexLogoaPainter({required this.glowIntensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;

    // Outer hex
    final hexPath = _buildHexPath(center, radius);
    
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * glowIntensity)
      ..color = AppColors.primary.withOpacity(0.6 * glowIntensity);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withOpacity(0.08);

    canvas.drawPath(hexPath, fillPaint);
    canvas.drawPath(hexPath, glowPaint);
    canvas.drawPath(hexPath, borderPaint);

    // Inner hex
    final innerHex = _buildHexPath(center, radius * 0.6);
    final innerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.secondary.withOpacity(0.7);
    canvas.drawPath(innerHex, innerBorderPaint);

    // BRL text (simplified as dots in a chain pattern)
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary;
    
    final positions = [
      center.translate(-10, 0),
      center,
      center.translate(10, 0),
    ];
    for (int i = 0; i < positions.length; i++) {
      if (i > 0) {
        canvas.drawLine(
          positions[i - 1],
          positions[i],
          Paint()
            ..color = AppColors.primary.withOpacity(0.5)
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(positions[i], 3, dotPaint);
    }
  }

  Path _buildHexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexLogoaPainter oldDelegate) =>
      oldDelegate.glowIntensity != glowIntensity;
}
