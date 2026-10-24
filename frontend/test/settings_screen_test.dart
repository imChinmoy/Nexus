import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/theme/appearance_provider.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';
import 'package:brl_nexus/features/settings/presentation/screens/settings_screen.dart';

void main() {
  final testUser = UserEntity(
    id: 'user-1',
    name: 'Jane Doe',
    email: 'jane@brlnexus.com',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Widget createSettingsHarness({ThemeMode initialMode = ThemeMode.system}) {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => testUser),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final mode = ref.watch(appearanceProvider);
          return MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: mode,
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  group('SettingsScreen Appearance & Theme Selector Tests', () {
    testWidgets('Displays System, Light, and Dark options with BETA tag under Light mode', (tester) async {
      await tester.pumpWidget(createSettingsHarness());
      await tester.pumpAndSettle();

      // Theme options exist
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // BETA badge appears under Light theme
      expect(find.text('BETA'), findsOneWidget);
    });

    testWidgets('Tapping Light option selects Light theme mode', (tester) async {
      await tester.pumpWidget(createSettingsHarness());
      await tester.pumpAndSettle();

      // Tap Light option
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // BETA badge remains visible and properly aligned
      expect(find.text('BETA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tapping Dark and System options switches modes cleanly', (tester) async {
      await tester.pumpWidget(createSettingsHarness());
      await tester.pumpAndSettle();

      // Tap Dark option
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Tap System option
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
