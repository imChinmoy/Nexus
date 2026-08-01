import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Base Background
  static const Color background = Color(0xFF0A0F1E);
  static const Color surface = Color(0xFF0D1527);
  static const Color surfaceDark = Color(0xFF080C18);
  static const Color surfaceGlass = Color(0x0DFFFFFF);
  static const Color surfaceCard = Color(0x0DFFFFFF);

  // Primary - Cyan Neon
  static const Color primary = Color(0xFF00F5FF);
  static const Color primaryGlow = Color(0x4D00F5FF);
  static const Color primaryDim = Color(0xFF00C8D4);
  static const Color onPrimary = Color(0xFF0A0F1E);

  // Secondary - Purple
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryGlow = Color(0x4D7C3AED);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Accent - Pink
  static const Color accentPink = Color(0xFFFF006E);
  static const Color accentPinkGlow = Color(0x4DFF006E);

  // Accent - Green (Attendance)
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentGreenGlow = Color(0x4D00FF88);

  // Accent - Amber (Reports)
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color accentAmberGlow = Color(0x4DFFB800);

  // Text
  static const Color onSurface = Color(0xFFE2E8F0);
  static const Color onSurfaceMuted = Color(0xFF94A3B8);
  static const Color onSurfaceSubtle = Color(0xFF475569);

  // Status
  static const Color success = Color(0xFF00FF88);
  static const Color error = Color(0xFFFF4444);
  static const Color warning = Color(0xFFFFB800);
  static const Color info = Color(0xFF00F5FF);

  // Glass
  static const Color glassStroke = Color(0x2600F5FF);
  static const Color glassStrokeHover = Color(0x6600F5FF);
  static const Color glassStrokePurple = Color(0x267C3AED);
  static const Color glassStrokePink = Color(0x26FF006E);
  static const Color glassStrokeGreen = Color(0x2600FF88);
  static const Color glassStrokeAmber = Color(0x26FFB800);

  // Gradient stops
  static const List<Color> primaryGradient = [primary, secondary];
  static const List<Color> secondaryGradient = [secondary, accentPink];
  static const List<Color> accentGradient = [accentPink, accentAmber];
  static const List<Color> bgGradient1 = [Color(0xFF0A0F1E), Color(0xFF0D1527)];
  static const List<Color> bgGradient2 = [Color(0xFF0D1527), Color(0xFF12082A)];
  static const List<Color> bgGradient3 = [Color(0xFF12082A), Color(0xFF0A0F1E)];

  // Module colors
  static const Color moduleDashboard = primary;
  static const Color moduleStudents = Color(0xFF0EA5E9);
  static const Color moduleMembers = secondary;
  static const Color moduleEvents = accentPink;
  static const Color moduleAttendance = accentGreen;
  static const Color moduleReports = accentAmber;
  static const Color moduleSettings = Color(0xFF64748B);
}
