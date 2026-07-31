class AppConstants {
  AppConstants._();

  static const String appName = 'BRL Nexus';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  static const String tagline = 'Blockchain Research Lab';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String onboardingKey = 'onboarding_done';

  // Hive boxes
  static const String settingsBox = 'settings_box';
  static const String userBox = 'user_box';
  static const String cacheBox = 'cache_box';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 1);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // QR
  static const Duration qrExpiry = Duration(minutes: 10);
  static const int qrRefreshSeconds = 30;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animBgCycle = Duration(seconds: 8);
}
