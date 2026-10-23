import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../storage/hive_service.dart';

final appearanceProvider = StateNotifierProvider<AppearanceNotifier, ThemeMode>((ref) {
  return AppearanceNotifier();
});

class AppearanceNotifier extends StateNotifier<ThemeMode> {
  AppearanceNotifier() : super(_loadInitialTheme());

  static ThemeMode _loadInitialTheme() {
    try {
      final saved = HiveService.settings.get(AppConstants.themeKey) as String?;
      switch (saved) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final value = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await HiveService.settings.put(AppConstants.themeKey, value);
    } catch (_) {}
  }
}
