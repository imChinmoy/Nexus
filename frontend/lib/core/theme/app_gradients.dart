import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2997FF), Color(0xFF5E5CE6)],
  );

  static const LinearGradient secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5E5CE6), Color(0xFFFF375F)],
  );

  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF375F), Color(0xFFFF9F0A)],
  );

  static const LinearGradient attendance = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF30D158), Color(0xFF2997FF)],
  );

  static const LinearGradient reports = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9F0A), Color(0xFFFF375F)],
  );

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF111114),
      Color(0xFF18181C),
    ],
  );

  static LinearGradient forModule(ModuleGradient module) {
    switch (module) {
      case ModuleGradient.dashboard:
        return primary;
      case ModuleGradient.students:
        return const LinearGradient(
          colors: [Color(0xFF0A84FF), Color(0xFF2997FF)],
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
