class RouteConstants {
  RouteConstants._();

  // Auth
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Shell routes (bottom nav)
  static const String shell = '/';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Students
  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static const String addStudent = '/students/add';
  static const String editStudent = '/students/:id/edit';

  // Members
  static const String members = '/members';
  static const String memberDetail = '/members/:id';
  static const String addMember = '/members/add';

  // Events
  static const String events = '/events';
  static const String eventDetail = '/events/:id';
  static const String createEvent = '/events/create';
  static const String editEvent = '/events/:id/edit';

  // Attendance
  static const String attendance = '/attendance';
  static const String qrScanner = '/attendance/qr-scan';
  static const String qrDisplay = '/attendance/qr-display';
  static const String manualAttendance = '/attendance/manual';

  // Reports
  static const String reports = '/reports';

  // Settings
  static const String settings = '/settings';
  static const String profile = '/settings/profile';
  static const String changePassword = '/settings/change-password';

  // Notifications
  static const String notifications = '/notifications';

  // Audit Logs
  static const String auditLogs = '/audit-logs';
}
