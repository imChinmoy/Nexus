import 'package:flutter/material.dart';
import 'nexus_splash_painter.dart';

/// Interactive animated widget for the Nexus mark from [assets/animations/splash.svg].
///
/// Executes the 2800ms SMIL timeline faithfully on Flutter Canvas with 60/120 FPS
/// hardware acceleration, holding the final completed frame.
class NexusSplashAnimation extends StatefulWidget {
  final double size;
  final Duration duration;
  final VoidCallback? onCompleted;

  const NexusSplashAnimation({
    super.key,
    this.size = 280.0,
    this.duration = const Duration(milliseconds: 2800),
    this.onCompleted,
  });

  @override
  State<NexusSplashAnimation> createState() => _NexusSplashAnimationState();
}

class _NexusSplashAnimationState extends State<NexusSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onCompleted?.call();
      }
    });

    _controller.forward();
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
          painter: NexusSplashMarkPainter(
            progress: _controller.value,
          ),
        );
      },
    );
  }
}
