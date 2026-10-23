import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/theme/app_colors.dart';

void main() {
  group('Apple-Inspired Design System Color Tokens', () {
    test('Light mode tokens match Apple Human Interface Guidelines', () {
      expect(AppColors.lightBackground, const Color(0xFFF5F5F7));
      expect(AppColors.lightSurface, const Color(0xFFFFFFFF));
      expect(AppColors.lightTextPrimary, const Color(0xFF1D1D1F));
      expect(AppColors.lightTextSecondary, const Color(0xFF6E6E73));
      expect(AppColors.lightSeparator, const Color(0xFFE5E5EA));
      expect(AppColors.lightAccent, const Color(0xFF0071E3));
    });

    test('Dark mode tokens match Apple dark slate & graphite', () {
      expect(AppColors.darkBackground, const Color(0xFF111114));
      expect(AppColors.darkSurface, const Color(0xFF1C1C1F));
      expect(AppColors.darkElevatedSurface, const Color(0xFF242428));
      expect(AppColors.darkTextPrimary, const Color(0xFFF5F5F7));
      expect(AppColors.darkTextSecondary, const Color(0xFFA1A1A6));
      expect(AppColors.darkSeparator, const Color(0xFF2C2C30));
      expect(AppColors.darkAccent, const Color(0xFF2997FF));
    });

    test('Semantic system colors meet contrast and meaning requirements', () {
      expect(AppColors.success, const Color(0xFF34C759));
      expect(AppColors.successDark, const Color(0xFF30D158));
      expect(AppColors.warning, const Color(0xFFFF9500));
      expect(AppColors.warningDark, const Color(0xFFFF9F0A));
      expect(AppColors.error, const Color(0xFFFF3B30));
      expect(AppColors.errorDark, const Color(0xFFFF453A));
    });

    testWidgets('Context helpers resolve light vs dark accurately', (tester) async {
      late BuildContext lightContext;
      late BuildContext darkContext;

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Builder(
            builder: (context) {
              lightContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(AppColors.bgOf(lightContext), AppColors.lightBackground);
      expect(AppColors.surfaceOf(lightContext), AppColors.lightSurface);
      expect(AppColors.textPrimaryOf(lightContext), AppColors.lightTextPrimary);
      expect(AppColors.accentOf(lightContext), AppColors.lightAccent);
      expect(AppColors.borderOf(lightContext), AppColors.lightSeparator);
      expect(AppColors.successOf(lightContext), AppColors.success);
      expect(AppColors.errorOf(lightContext), AppColors.error);

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Builder(
            builder: (context) {
              darkContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(AppColors.bgOf(darkContext), AppColors.darkBackground);
      expect(AppColors.surfaceOf(darkContext), AppColors.darkSurface);
      expect(AppColors.textPrimaryOf(darkContext), AppColors.darkTextPrimary);
      expect(AppColors.accentOf(darkContext), AppColors.darkAccent);
      expect(AppColors.borderOf(darkContext), AppColors.darkSeparator);
      expect(AppColors.successOf(darkContext), AppColors.successDark);
      expect(AppColors.errorOf(darkContext), AppColors.errorDark);
    });
  });
}
