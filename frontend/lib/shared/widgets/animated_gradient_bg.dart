import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Clean Apple-inspired adaptive screen background container.
/// Provides a calm, consistent foundation that respects light and dark modes
/// without distracting decorative animations or battery-draining repaints.
class AnimatedGradientBg extends StatelessWidget {
  final Widget child;

  const AnimatedGradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Container(
      color: bgColor,
      child: child,
    );
  }
}
