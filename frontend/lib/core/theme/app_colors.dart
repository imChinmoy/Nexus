import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Dark Palette (Apple Charcoal & Graphite)
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF111114);
  static const Color darkSecondaryBackground = Color(0xFF18181C);
  static const Color darkSurface = Color(0xFF1C1C1F);
  static const Color darkElevatedSurface = Color(0xFF242428);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFFA1A1A6);
  static const Color darkTextTertiary = Color(0xFF636366);
  static const Color darkSeparator = Color(0xFF2C2C30);
  static const Color darkAccent = Color(0xFF2997FF);
  static const Color darkAccentMuted = Color(0x262997FF);

  // ---------------------------------------------------------------------------
  // Light Palette (Apple Crisp White & Subtle Warm Gray)
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSecondaryBackground = Color(0xFFEBEBEF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightElevatedSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightTextTertiary = Color(0xFF86868B);
  static const Color lightSeparator = Color(0xFFE5E5EA);
  static const Color lightAccent = Color(0xFF0071E3);
  static const Color lightAccentMuted = Color(0x1A0071E3);

  // ---------------------------------------------------------------------------
  // Semantic System Colors (Accessible in both modes)
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);
  static const Color successSubtle = Color(0x1F34C759);

  static const Color warning = Color(0xFFFF9500);
  static const Color warningDark = Color(0xFFFF9F0A);
  static const Color warningSubtle = Color(0x1FFF9500);

  static const Color error = Color(0xFFFF3B30);
  static const Color errorDark = Color(0xFFFF453A);
  static const Color errorSubtle = Color(0x1FFF3B30);

  static const Color info = Color(0xFF0071E3);
  static const Color infoDark = Color(0xFF2997FF);
  static const Color infoSubtle = Color(0x1F0071E3);

  // ---------------------------------------------------------------------------
  // Compatibility Constants (Refined to Apple palette)
  // ---------------------------------------------------------------------------
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color surfaceDark = darkSecondaryBackground;
  static const Color surfaceGlass = Color(0x1AFFFFFF);
  static const Color surfaceCard = darkSurface;

  // Primary brand accent
  static const Color primary = Color(0xFF2997FF);
  static const Color primaryGlow = Color(0x332997FF);
  static const Color primaryDim = Color(0xFF1B6FD8);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Secondary
  static const Color secondary = Color(0xFF5E5CE6);
  static const Color secondaryGlow = Color(0x335E5CE6);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Accents
  static const Color accentPink = Color(0xFFFF375F);
  static const Color accentPinkGlow = Color(0x33FF375F);
  static const Color accentGreen = Color(0xFF30D158);
  static const Color accentGreenGlow = Color(0x3330D158);
  static const Color accentAmber = Color(0xFFFF9F0A);
  static const Color accentAmberGlow = Color(0x33FF9F0A);

  // Text
  static const Color onSurface = darkTextPrimary;
  static const Color onSurfaceMuted = darkTextSecondary;
  static const Color onSurfaceSubtle = darkTextTertiary;

  // Glass & Borders (Subtle Apple hairline borders)
  static const Color glassStroke = Color(0x1FFFFFFF);
  static const Color glassStrokeHover = Color(0x33FFFFFF);
  static const Color glassStrokePurple = Color(0x335E5CE6);
  static const Color glassStrokePink = Color(0x33FF375F);
  static const Color glassStrokeGreen = Color(0x3330D158);
  static const Color glassStrokeAmber = Color(0x33FF9F0A);

  // Module Refined Accents
  static const Color moduleDashboard = Color(0xFF2997FF);
  static const Color moduleStudents = Color(0xFF0A84FF);
  static const Color moduleMembers = Color(0xFF5E5CE6);
  static const Color moduleEvents = Color(0xFFFF375F);
  static const Color moduleAttendance = Color(0xFF30D158);
  static const Color moduleReports = Color(0xFFFF9F0A);
  static const Color moduleSettings = Color(0xFF8E8E93);

  // Gradients (Subtle & Restrained)
  static const List<Color> primaryGradient = [
    Color(0xFF2997FF),
    Color(0xFF5E5CE6)
  ];
  static const List<Color> secondaryGradient = [
    Color(0xFF5E5CE6),
    Color(0xFFFF375F)
  ];
  static const List<Color> accentGradient = [
    Color(0xFFFF375F),
    Color(0xFFFF9F0A)
  ];

  // ---------------------------------------------------------------------------
  // Context-aware color resolution helpers
  // ---------------------------------------------------------------------------
  static Color bgOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBackground
          : lightBackground;

  static Color surfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSurface
          : lightSurface;

  static Color elevatedSurfaceOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkElevatedSurface
          : lightElevatedSurface;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextPrimary
          : lightTextPrimary;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextSecondary
          : lightTextSecondary;

  static Color textTertiaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkTextTertiary
          : lightTextTertiary;

  static Color separatorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSeparator
          : lightSeparator;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSeparator
          : lightSeparator;

  static Color accentOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkAccent
          : lightAccent;

  static Color successOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? successDark : success;

  static Color warningOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? warningDark : warning;

  static Color errorOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? errorDark : error;

  static Color infoOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? infoDark : info;

  static Color cardBorderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0x1AFFFFFF)
          : const Color(0x0F000000);
}
