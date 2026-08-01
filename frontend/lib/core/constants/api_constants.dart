import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000/api';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String me = '/auth/me';
  static const String updateAvatar = '/auth/me/avatar';
  static const String changePassword = '/auth/change-password';

  // Students
  static const String students = '/students';
  static String studentById(String id) => '/students/$id';
  static const String importStudents = '/students/import';
  static const String exportStudents = '/students/export';

  // Members
  static const String members = '/members';
  static String memberById(String id) => '/members/$id';

  // Events
  static const String events = '/events';
  static String eventById(String id) => '/events/$id';
  static String eventAttendance(String id) => '/events/$id/attendance';

  // Attendance
  static const String attendance = '/attendance';
  static const String attendanceQr = '/attendance/qr';
  static const String attendanceScan = '/attendance/scan';
  static const String attendanceManual = '/attendance/manual';
  static const String attendanceBulk = '/attendance/bulk';
  static String attendanceByStudent(String id) => '/attendance/student/$id';
  static String attendanceByEvent(String id) => '/attendance/event/$id';

  // Reports
  static const String reports = '/reports';
  static const String reportsMonthly = '/reports/monthly';
  static const String reportsStudent = '/reports/student';
  static const String reportsEvent = '/reports/event';
  static const String reportsExport = '/reports/export';

  // Analytics
  static const String analytics = '/analytics';
  static const String analyticsOverview = '/analytics/overview';
  static const String analyticsTrends = '/analytics/trends';

  // Settings
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String auditLogs = '/audit-logs';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';
}
