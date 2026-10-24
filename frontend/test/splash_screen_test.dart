import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/features/auth/presentation/screens/splash_screen.dart';
import 'package:brl_nexus/features/auth/presentation/widgets/nexus_splash_animation.dart';
import 'package:brl_nexus/features/auth/presentation/widgets/nexus_splash_painter.dart';
import 'package:brl_nexus/features/auth/presentation/widgets/splash_background.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';

void main() {
  group('SplashBackground Widget Tests', () {
    testWidgets('Renders default gradient when bgImagePath is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplashBackground(
              bgImagePath: null,
              child: Center(child: Text('Content')),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('Renders Image.asset when bgImagePath is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SplashBackground(
              bgImagePath: 'assets/images/bg.png',
              child: Center(child: Text('With Background')),
            ),
          ),
        ),
      );

      expect(find.text('With Background'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('NexusSplashAnimation & Painter Tests', () {
    testWidgets('NexusSplashMarkPainter paints progress cleanly without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: NexusSplashMarkPainter(progress: 0.0),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Test mid progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: NexusSplashMarkPainter(progress: 0.5),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Test completed progress
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomPaint(
                size: const Size(280, 280),
                painter: NexusSplashMarkPainter(progress: 1.0),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('NexusSplashAnimation plays and triggers onCompleted callback', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexusSplashAnimation(
              size: 200,
              duration: const Duration(milliseconds: 500),
              onCompleted: () => completed = true,
            ),
          ),
        ),
      );

      expect(find.byType(NexusSplashAnimation), findsOneWidget);
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 250));
      expect(completed, isFalse);

      await tester.pump(const Duration(milliseconds: 300));
      expect(completed, isTrue);
    });
  });

  group('SplashScreen Screen Tests', () {
    testWidgets('Renders Nexus brand, Blockchain Research Lab, and animated mark', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(find.text('Nexus'), findsOneWidget);
      expect(find.text('BLOCKCHAIN RESEARCH LAB'), findsOneWidget);
      expect(find.byType(NexusSplashAnimation), findsOneWidget);
      expect(find.byType(SplashBackground), findsOneWidget);
    });

    testWidgets('Completes splash duration and updates splashAnimationCompletedProvider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(container.read(splashAnimationCompletedProvider), isFalse);

      // Advance clock past the splash duration (3200ms)
      await tester.pump(const Duration(milliseconds: 3300));
      await tester.pump(const Duration(milliseconds: 200));

      expect(container.read(splashAnimationCompletedProvider), isTrue);
    });

    testWidgets('User tapping screen can trigger skip to complete splash', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      expect(container.read(splashAnimationCompletedProvider), isFalse);

      // Tap screen to skip
      await tester.tap(find.byType(SplashScreen));
      await tester.pump();

      expect(container.read(splashAnimationCompletedProvider), isTrue);
    });
  });
}
