import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper to detect if any background image exists in assets/images/.
class SplashBackgroundFinder {
  static const List<String> _preferredImageNames = [
    'assets/images/bg.png',
    'assets/images/bg.jpg',
    'assets/images/bg.jpeg',
    'assets/images/bg.webp',
    'assets/images/splash_bg.png',
    'assets/images/splash_bg.jpg',
    'assets/images/splash_bg.jpeg',
    'assets/images/splash_bg.webp',
    'assets/images/background.png',
    'assets/images/background.jpg',
    'assets/images/background.jpeg',
    'assets/images/background.webp',
  ];

  static Future<String?> findBackgroundImage() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = manifest.listAssets();

      // 1. Check preferred filenames first
      for (final name in _preferredImageNames) {
        if (assets.contains(name)) {
          return name;
        }
      }

      // 2. Check any image file in assets/images/
      for (final asset in assets) {
        if (asset.startsWith('assets/images/')) {
          final lower = asset.toLowerCase();
          if (lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.webp')) {
            return asset;
          }
        }
      }
    } catch (_) {
      // Fallback silently if manifest is unavailable
    }
    return null;
  }
}

/// Renders either an optional background image from assets/images/ (if present),
/// or a clean, modern cybernetic gradient.
class SplashBackground extends StatelessWidget {
  final String? bgImagePath;
  final Widget child;

  const SplashBackground({
    super.key,
    required this.bgImagePath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base Layer: Image or Gradient
        if (bgImagePath != null) ...[
          Positioned.fill(
            child: Image.asset(
              bgImagePath!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _DefaultSplashGradient(),
            ),
          ),
          // Gradient overlay for contrast and legibility
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xB3050B14), // 70% dark navy
                    Color(0xCC050B14), // 80% dark navy
                    Color(0xF202050B), // 95% dark void
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ] else ...[
          const Positioned.fill(
            child: _DefaultSplashGradient(),
          ),
        ],

        // 2. Ambient subtle cyan/blue glow in center for depth
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.15),
                radius: 0.85,
                colors: [
                  Color(0x181687FF), // Subtle cyber blue ambient glow
                  Color(0x0877D8FF), // Very soft cyan fringe
                  Colors.transparent,
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // 3. Foreground content
        child,
      ],
    );
  }
}

class _DefaultSplashGradient extends StatelessWidget {
  const _DefaultSplashGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1324), // Rich deep navy
            Color(0xFF060B14), // Pure dark nexus theme
            Color(0xFF03060B), // Deep void black
          ],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}
