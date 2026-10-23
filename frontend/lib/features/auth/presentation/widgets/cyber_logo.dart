import 'package:flutter/material.dart';

class CyberLogo extends StatelessWidget {
  final double size;

  const CyberLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1F) : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : const Color(0x0F000000),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(
        'assets/icons/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.hub_rounded,
              size: size * 0.5,
              color: isDark ? const Color(0xFF2997FF) : const Color(0xFF0071E3),
            ),
          );
        },
      ),
    );
  }
}
