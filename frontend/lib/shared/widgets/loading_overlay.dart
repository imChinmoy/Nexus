import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _NexusLoader(),
                    if (message != null) ...
                      [
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontFamily: 'JetBrains Mono',
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ]
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NexusLoader extends StatefulWidget {
  const _NexusLoader();

  @override
  State<_NexusLoader> createState() => _NexusLoaderState();
}

class _NexusLoaderState extends State<_NexusLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
      builder: (_, __) => SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(
          value: null,
          strokeWidth: 2,
          color: AppColors.primary,
          backgroundColor: AppColors.primaryGlow,
        ),
      ),
    );
  }
}
