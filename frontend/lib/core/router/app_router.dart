import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/students/presentation/screens/students_screen.dart';
import '../../features/students/presentation/screens/student_detail_screen.dart';
import '../../features/students/presentation/screens/add_student_screen.dart';
import '../../features/members/presentation/screens/members_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/events/presentation/screens/event_detail_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/attendance/presentation/screens/qr_scanner_screen.dart';
import '../../features/attendance/presentation/screens/qr_display_screen.dart';
import '../../features/attendance/presentation/screens/manual_attendance_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/change_password_screen.dart';
import '../../shared/widgets/brl_bottom_nav.dart';
import '../constants/route_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final isAuthRoute = state.matchedLocation == RouteConstants.login ||
          state.matchedLocation == RouteConstants.forgotPassword;
      final isSplashRoute = state.matchedLocation == RouteConstants.splash;

      return authState.when(
        initial: () => isSplashRoute ? null : RouteConstants.splash,
        loading: () => isSplashRoute ? null : RouteConstants.splash,
        authenticated: (_) => isAuthRoute || isSplashRoute ? RouteConstants.dashboard : null,
        unauthenticated: () => isAuthRoute ? null : RouteConstants.login,
        error: (_) => isAuthRoute ? null : RouteConstants.login,
      );
    },
    routes: [
      // Splash route
      GoRoute(
        path: RouteConstants.splash,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth routes
      GoRoute(
        path: RouteConstants.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Shell route with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => BrlBottomNav(child: child),
        routes: [
          GoRoute(
            path: RouteConstants.dashboard,
            pageBuilder: (context, state) =>
                _buildPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: RouteConstants.students,
            pageBuilder: (context, state) =>
                _buildPage(state, const StudentsScreen()),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const AddStudentScreen(),
              ),
              GoRoute(
                path: ':studentId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    StudentDetailScreen(studentId: state.pathParameters['studentId']!),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.members,
            pageBuilder: (context, state) =>
                _buildPage(state, const MembersScreen()),
          ),
          GoRoute(
            path: RouteConstants.events,
            pageBuilder: (context, state) =>
                _buildPage(state, const EventsScreen()),
            routes: [
              GoRoute(
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CreateEventScreen(),
              ),
              GoRoute(
                path: ':eventId',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    EventDetailScreen(eventId: state.pathParameters['eventId']!),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.attendance,
            pageBuilder: (context, state) =>
                _buildPage(state, const AttendanceScreen()),
            routes: [
              GoRoute(
                path: 'qr-scan',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => QrScannerScreen(
                  eventId: state.uri.queryParameters['eventId'] ?? '',
                ),
              ),
              GoRoute(
                path: 'qr-display',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => QrDisplayScreen(
                  eventId: state.uri.queryParameters['eventId'] ?? '',
                ),
              ),
              GoRoute(
                path: 'manual',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => ManualAttendanceScreen(
                  eventId: state.uri.queryParameters['eventId'] ?? '',
                ),
              ),
            ],
          ),
          GoRoute(
            path: RouteConstants.reports,
            pageBuilder: (context, state) =>
                _buildPage(state, const ReportsScreen()),
          ),
          GoRoute(
            path: RouteConstants.settings,
            pageBuilder: (context, state) =>
                _buildPage(state, const SettingsScreen()),
            routes: [
              GoRoute(
                path: 'profile',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ProfileScreen(),
              ),
              GoRoute(
                path: 'change-password',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const ChangePasswordScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Center(
        child: Text(
          '404 - Page not found',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    ),
  );
});

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 250),
  );
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}
