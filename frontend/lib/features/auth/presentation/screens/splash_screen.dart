import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auth_state.dart';
import '../widgets/nexus_splash_animation.dart';
import '../widgets/splash_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _bgImagePath;
  bool _animationCompleted = false;
  Timer? _fallbackTimer;

  // Total duration: 3200ms allows the full 2800ms SVG animation to play completely
  // and hold its final frame for 400ms.
  static const Duration _splashDuration = Duration(milliseconds: 3200);

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();

    // Ensure checkAuthStatus has been triggered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthInitial) {
        ref.read(authNotifierProvider.notifier).checkAuthStatus();
      }
    });

    // Safety fallback timer in case of animation callback anomalies
    _fallbackTimer = Timer(_splashDuration + const Duration(milliseconds: 400), () {
      if (mounted && !_animationCompleted) {
        _handleSplashFinish();
      }
    });
  }

  Future<void> _loadBackgroundImage() async {
    final imagePath = await SplashBackgroundFinder.findBackgroundImage();
    if (mounted) {
      setState(() {
        _bgImagePath = imagePath;
      });
    }
  }

  void _handleSplashFinish() {
    if (_animationCompleted) return;
    _animationCompleted = true;
    if (mounted) {
      ref.read(splashAnimationCompletedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final animSize = (size.shortestSide * 0.70).clamp(240.0, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF050B14),
      body: SplashBackground(
        bgImagePath: _bgImagePath,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_animationCompleted) {
                _handleSplashFinish();
              }
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // The Animated Nexus Mark from splash.svg
                  NexusSplashAnimation(
                    size: animSize,
                    duration: _splashDuration,
                    onCompleted: _handleSplashFinish,
                  ),

                  const SizedBox(height: 24),

                  // Brand Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Color(0xFFE0F2FE),
                        Color(0xFF77D8FF),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ).createShader(bounds),
                    child: Text(
                      'Nexus',
                      style: AppTextStyles.displayLg.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Society Subtitle with cyber tracking
                  Text(
                    'BLOCKCHAIN RESEARCH LAB',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF77D8FF),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.4,
                      fontSize: 11,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Futuristic System Status Micro-Indicator
                  Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authNotifierProvider);
                      final isResolving = authState is AuthLoading ||
                          authState is AuthInitial;

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isResolving ? 0.8 : 0.4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF77D8FF),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x6677D8FF),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isResolving ? 'CONNECTING PROTOCOL' : 'SYSTEM READY',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
