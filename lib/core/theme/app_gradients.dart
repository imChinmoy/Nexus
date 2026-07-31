import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.accentPink],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentPink, AppColors.accentAmber],
  );

  static const LinearGradient attendance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentGreen, AppColors.primary],
  );

  static const LinearGradient reports = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accentAmber, AppColors.accentPink],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0F1E),
      Color(0xFF0D1527),
      Color(0xFF12082A),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static LinearGradient forModule(ModuleGradient module) {
    switch (module) {
      case ModuleGradient.dashboard:
        return primary;
      case ModuleGradient.students:
        return const LinearGradient(
          colors: [Color(0xFF0EA5E9), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ModuleGradient.members:
        return secondary;
      case ModuleGradient.events:
        return accent;
      case ModuleGradient.attendance:
        return attendance;
      case ModuleGradient.reports:
        return reports;
    }
  }
}

enum ModuleGradient {
  dashboard,
  students,
  members,
  events,
  attendance,
  reports,
}
