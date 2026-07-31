import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AnimatedGradientBg extends StatefulWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  final List<_Particle> _particles = [];
  final int _particleCount = 20;

  // Gradient cycles
  static const _stops = [
    [Color(0xFF0A0F1E), Color(0xFF0D1527), Color(0xFF0A0F1E)],
    [Color(0xFF0D1527), Color(0xFF12082A), Color(0xFF0D1527)],
    [Color(0xFF12082A), Color(0xFF0A0F1E), Color(0xFF12082A)],
  ];

  int _currentStop = 0;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _currentStop = (_currentStop + 1) % _stops.length);
          _gradientController.forward(from: 0);
        }
      });
    _gradientAnimation = CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    );
    _gradientController.forward();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _initParticles();
  }

  void _initParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(_Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 3 + 1,
        opacity: random.nextDouble() * 0.5 + 0.1,
        speed: random.nextDouble() * 0.002 + 0.001,
        color: i % 3 == 0
            ? AppColors.primary
            : i % 3 == 1
                ? AppColors.secondary
                : AppColors.accentPink,
      ));
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = (_currentStop + 1) % _stops.length;
    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, _) {
        final t = _gradientAnimation.value;
        final colors = [
          Color.lerp(_stops[_currentStop][0], _stops[next][0], t)!,
          Color.lerp(_stops[_currentStop][1], _stops[next][1], t)!,
          Color.lerp(_stops[_currentStop][2], _stops[next][2], t)!,
        ];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: Stack(
            children: [
              // Hex grid overlay
              const _HexGridOverlay(),
              // Particles
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, _) {
                  final time = _particleController.value;
                  return CustomPaint(
                    painter: _ParticlePainter(_particles, time),
                    size: Size.infinite,
                  );
                },
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _HexGridOverlay extends StatelessWidget {
  const _HexGridOverlay();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.03,
      child: CustomPaint(
        painter: _HexGridPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _HexGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const hexSize = 40.0;
    const w = hexSize * 2;
    final h = hexSize * 1.7320508075688772;

    for (double y = -h; y < size.height + h; y += h) {
      for (double x = -w; x < size.width + w; x += w * 0.75) {
        final offsetY = ((x / (w * 0.75)).floor() % 2 == 0) ? 0.0 : h / 2;
        _drawHex(canvas, paint, Offset(x, y + offsetY), hexSize);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final point = Offset(
        center.dx + size * math.cos(angle),
        center.dy + size * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Particle {
  double x, y;
  final double size;
  final double opacity;
  final double speed;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - p.speed * time * 10) % 1.0;
      final x = p.x;
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.time != time;
}

extension on math.Random {
  // ignore: unused_element
}

const double math_sqrt3 = 1.7320508075688772;
extension _MathExt on num {
  static const sqrt3 = 1.7320508075688772;
}
