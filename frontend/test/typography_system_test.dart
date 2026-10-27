import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/theme/app_colors.dart';
import 'package:brl_nexus/core/theme/app_text_styles.dart';
import 'package:brl_nexus/core/theme/app_theme.dart';

void main() {
  group('Typography System - Design System & Font Hierarchy', () {
    test('Font family constants are correctly defined', () {
      expect(AppTextStyles.displayFontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.interfaceFontFamily, equals('IBMPlexSans'));
    });

    test('Display and headline typography use Space Grotesk', () {
      expect(AppTextStyles.displayLg.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.displayMd.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.displaySm.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.headlineLg.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.headlineMd.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.headlineSm.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.titleLg.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.cardTitle.fontFamily, equals('SpaceGrotesk'));
    });

    test('Interface, body, and button typography use IBM Plex Sans', () {
      expect(AppTextStyles.bodyLg.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.bodyMd.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.bodySm.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.titleMd.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.titleSm.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.sectionTitle.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.labelLg.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.labelMd.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.labelSm.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.caption.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.buttonLg.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.buttonMd.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.buttonSm.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.button.fontFamily, equals('IBMPlexSans'));
    });

    test('Selective italic typography uses IBM Plex Sans with FontStyle.italic',
        () {
      expect(AppTextStyles.editorialSubtitle.fontFamily, equals('IBMPlexSans'));
      expect(
          AppTextStyles.editorialSubtitle.fontStyle, equals(FontStyle.italic));

      expect(AppTextStyles.editorialQuote.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.editorialQuote.fontStyle, equals(FontStyle.italic));

      expect(AppTextStyles.bodyItalic.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.bodyItalic.fontStyle, equals(FontStyle.italic));

      expect(AppTextStyles.captionItalic.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.captionItalic.fontStyle, equals(FontStyle.italic));
    });

    test('Tabular figures are enabled for metrics and counters', () {
      expect(AppTextStyles.metricLg.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.metricLg.fontFeatures, isNotNull);
      expect(
        AppTextStyles.metricLg.fontFeatures!.any((f) => f.feature == 'tnum'),
        isTrue,
      );

      expect(AppTextStyles.metricMd.fontFamily, equals('SpaceGrotesk'));
      expect(AppTextStyles.metricMd.fontFeatures, isNotNull);
      expect(
        AppTextStyles.metricMd.fontFeatures!.any((f) => f.feature == 'tnum'),
        isTrue,
      );

      expect(AppTextStyles.monoCode.fontFamily, equals('IBMPlexSans'));
      expect(AppTextStyles.monoCode.fontFeatures, isNotNull);
      expect(
        AppTextStyles.monoCode.fontFeatures!.any((f) => f.feature == 'tnum'),
        isTrue,
      );
    });
  });

  group('Typography System - ThemeData TextTheme Integration', () {
    test('Dark theme textTheme maps to correct font families and colors', () {
      final darkTheme = AppTheme.dark;
      final textTheme = darkTheme.textTheme;

      // Space Grotesk display roles
      expect(textTheme.displayLarge?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.displayMedium?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.displaySmall?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.headlineLarge?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.headlineMedium?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.headlineSmall?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.titleLarge?.fontFamily, equals('SpaceGrotesk'));

      // IBM Plex Sans interface roles
      expect(textTheme.titleMedium?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.titleSmall?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.bodyLarge?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.bodyMedium?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.bodySmall?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.labelLarge?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.labelMedium?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.labelSmall?.fontFamily, equals('IBMPlexSans'));

      // Dark theme colors
      expect(textTheme.displayLarge?.color, equals(AppColors.darkTextPrimary));
      expect(textTheme.bodyMedium?.color, equals(AppColors.darkTextPrimary));
      expect(textTheme.bodySmall?.color, equals(AppColors.darkTextSecondary));
    });

    test('Light theme textTheme maps to correct font families and colors', () {
      final lightTheme = AppTheme.light;
      final textTheme = lightTheme.textTheme;

      // Space Grotesk display roles
      expect(textTheme.displayLarge?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.headlineLarge?.fontFamily, equals('SpaceGrotesk'));
      expect(textTheme.titleLarge?.fontFamily, equals('SpaceGrotesk'));

      // IBM Plex Sans interface roles
      expect(textTheme.bodyLarge?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.bodyMedium?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.bodySmall?.fontFamily, equals('IBMPlexSans'));
      expect(textTheme.labelLarge?.fontFamily, equals('IBMPlexSans'));

      // Light theme colors
      expect(textTheme.displayLarge?.color, equals(AppColors.lightTextPrimary));
      expect(textTheme.bodyMedium?.color, equals(AppColors.lightTextPrimary));
      expect(textTheme.bodySmall?.color, equals(AppColors.lightTextSecondary));
    });
  });

  group('Typography System - Widget Rendering', () {
    testWidgets(
        'Renders headings, interface body, and selective italics in dark theme',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                Text('Society, in motion.', style: AppTextStyles.displayLg),
                Text(
                  'Every event brings the community together.',
                  style: AppTextStyles.editorialSubtitle,
                ),
                Text('Regular body paragraph', style: AppTextStyles.bodyMedium),
                Text('4,892 Attendees', style: AppTextStyles.metricLg),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Society, in motion.'), findsOneWidget);
      expect(find.text('Every event brings the community together.'),
          findsOneWidget);
      expect(find.text('Regular body paragraph'), findsOneWidget);
      expect(find.text('4,892 Attendees'), findsOneWidget);
    });

    testWidgets('Renders in light theme without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                Text('Upcoming Events', style: AppTextStyles.headlineMd),
                Text('Filter by society', style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Upcoming Events'), findsOneWidget);
      expect(find.text('Filter by society'), findsOneWidget);
    });
  });
}
