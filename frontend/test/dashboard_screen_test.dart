import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';
import 'package:brl_nexus/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';
import 'package:brl_nexus/features/events/domain/repositories/event_repository.dart';
import 'package:brl_nexus/features/events/providers/event_provider.dart';
import 'package:brl_nexus/features/students/domain/entities/student_entity.dart';
import 'package:brl_nexus/features/students/domain/repositories/student_repository.dart';
import 'package:brl_nexus/features/students/providers/student_provider.dart';
import 'package:brl_nexus/shared/widgets/brl_bottom_nav.dart';

class MockEventRepository implements EventRepository {
  List<EventEntity> mockEvents;

  MockEventRepository({List<EventEntity>? events})
      : mockEvents = events ??
            [
              EventEntity(
                id: 'event-featured-1',
                title: 'Tech Operations Summit 2026',
                description: 'Annual technical operations flagship conference',
                venue: 'Main Auditorium, Campus North',
                banner: 'https://example.com/banner1.jpg',
                startDate: DateTime(2026, 10, 24, 10, 0),
                endDate: DateTime(2026, 10, 24, 16, 0),
                type: 'summit',
                capacity: 250,
                status: 'ongoing',
                isAttendanceOpen: true,
              ),
              EventEntity(
                id: 'event-upcoming-2',
                title: 'AI Dev Workshop',
                description: 'Hands-on AI systems lab',
                venue: 'Lab 4',
                banner: 'https://example.com/banner2.jpg',
                startDate: DateTime(2026, 10, 28, 14, 0),
                endDate: DateTime(2026, 10, 28, 17, 0),
                type: 'workshop',
                capacity: 60,
                status: 'upcoming',
                isAttendanceOpen: false,
              ),
            ];

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents() async {
    return Right(mockEvents);
  }

  @override
  Future<Either<Failure, EventEntity>> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
    String? description,
    String? venue,
    String? bannerPath,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, EventEntity>> updateEvent(
    String id, {
    String? title,
    String? description,
    String? venue,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? capacity,
    String? bannerPath,
  }) async =>
      throw UnimplementedError();
}

class MockStudentRepository implements StudentRepository {
  List<StudentEntity> mockStudents;

  MockStudentRepository({List<StudentEntity>? students})
      : mockStudents = students ??
            const [
              StudentEntity(
                id: 'std-1',
                name: 'Aarav Sharma',
                rollNumber: '2100290100001',
                studentNo: '210001',
                branch: 'CSE',
                year: 3,
                email: 'aarav@akgec.ac.in',
                isPresent: true,
                attendanceStatus: 'present',
              ),
              StudentEntity(
                id: 'std-2',
                name: 'Bhavna Verma',
                rollNumber: '2100290100002',
                studentNo: '210002',
                branch: 'IT',
                year: 3,
                email: 'bhavna@akgec.ac.in',
                isPresent: true,
                attendanceStatus: 'present',
              ),
              StudentEntity(
                id: 'std-3',
                name: 'Chirag Gupta',
                rollNumber: '2100290100003',
                studentNo: '210003',
                branch: 'ECE',
                year: 2,
                email: 'chirag@akgec.ac.in',
                isPresent: false,
                attendanceStatus: null,
              ),
            ];

  @override
  Future<Either<Failure, List<StudentEntity>>> getStudents({String? search}) async {
    return Right(mockStudents);
  }

  @override
  Future<Either<Failure, EventStudentsResultEntity>> getStudentsByEvent(
    String eventId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? branch,
    String? attendanceStatus,
  }) async {
    final present = mockStudents.where((s) => s.isPresent).length;
    final total = mockStudents.length;
    return Right(
      EventStudentsResultEntity(
        students: mockStudents,
        total: total,
        page: page,
        limit: limit,
        totalPages: 1,
        counts: EventStudentCountsEntity(
          total: total,
          present: present,
          notMarked: total - present,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, StudentEntity>> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  }) async =>
      throw UnimplementedError();
}

Widget createTestDashboard({
  required MockEventRepository eventRepo,
  required MockStudentRepository studentRepo,
  ThemeMode themeMode = ThemeMode.dark,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(eventRepo),
      studentRepositoryProvider.overrideWithValue(studentRepo),
      currentUserProvider.overrideWith(
        (ref) => UserEntity(
          id: 'user-ops-1',
          name: 'Chinmoy Administrator',
          email: 'chinmoy@akgec.ac.in',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111114),
      ),
      home: const Scaffold(
        body: DashboardScreen(),
        bottomNavigationBar: SizedBox(
          height: 50,
          child: Row(
            children: [
              Text('Ops'),
              Text('Events'),
              Text('Scan'),
              Text('Students'),
              Text('Settings'),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DashboardScreen "Event Operations" Redesign Tests', () {
    testWidgets('Renders minimal header with NEXUS • OPS mark, greeting, date, and profile avatar',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      // Brand mark
      expect(find.text('NEXUS • OPS'), findsOneWidget);

      // Greeting with user name
      expect(find.textContaining('Chinmoy'), findsOneWidget);

      // Notification icon and avatar
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.text('C'), findsOneWidget); // Initial 'C' for Chinmoy
    });

    testWidgets('Renders Featured Event hero card with banner, live status, and prominent Scan QR action',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      // Featured event title
      expect(find.text('Tech Operations Summit 2026'), findsOneWidget);

      // Live status badge
      expect(find.text('LIVE CHECK-IN OPEN'), findsOneWidget);

      // Venue and metadata
      expect(find.textContaining('Main Auditorium'), findsOneWidget);

      // Prominent Scan QR Pass button
      expect(find.text('Scan QR Pass'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsWidgets);
    });

    testWidgets('Renders Attendance Overview as single compact horizontal statistics section',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      // Section header
      expect(find.text('ATTENDANCE OPERATIONS'), findsOneWidget);

      // Horizontal metrics (Present, Registered, Progress)
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Registered'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 present
      expect(find.text('3'), findsOneWidget); // 3 total
      expect(find.text('67%'), findsOneWidget); // 2/3 = 67%

      // Linear progress bar indicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders Recent Activity in a connected timeline without oversized card wrapping',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      // Section Header
      expect(find.text('RECENT ACTIVITY'), findsOneWidget);

      // Students present in timeline
      expect(find.text('Bhavna Verma'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);

      // Verification pill
      expect(find.text('Verified'), findsWidgets);
    });

    testWidgets('Renders Upcoming Events in an image-led horizontal carousel',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      // Header
      expect(find.text('UPCOMING SCHEDULE'), findsOneWidget);

      // Upcoming event title
      expect(find.text('AI Dev Workshop'), findsOneWidget);
      expect(find.text('UPCOMING'), findsOneWidget);
    });

    testWidgets('Renders cleanly in both Light Mode and Dark Mode',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository();
      final studentRepo = MockStudentRepository();

      // Light mode
      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
        themeMode: ThemeMode.light,
      ));
      await tester.pumpAndSettle();
      expect(find.text('NEXUS • OPS'), findsOneWidget);
      expect(find.text('Tech Operations Summit 2026'), findsOneWidget);

      // Dark mode
      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();
      expect(find.text('NEXUS • OPS'), findsOneWidget);
      expect(find.text('Tech Operations Summit 2026'), findsOneWidget);
    });

    testWidgets('Gracefully renders empty state when no events are available',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eventRepo = MockEventRepository(events: []);
      final studentRepo = MockStudentRepository(students: []);

      await tester.pumpWidget(createTestDashboard(
        eventRepo: eventRepo,
        studentRepo: studentRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Active or Scheduled Events'), findsOneWidget);
      expect(find.text('No check-ins recorded yet today'), findsOneWidget);
      expect(find.text('No upcoming events scheduled'), findsOneWidget);
    });

    testWidgets('BrlBottomNav renders slimmer profile with integrated Scan shortcut',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          ShellRoute(
            builder: (context, state, child) => BrlBottomNav(child: child),
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const Text('Dashboard Content'),
              ),
              GoRoute(
                path: '/events',
                builder: (context, state) => const Text('Events Content'),
              ),
              GoRoute(
                path: '/students',
                builder: (context, state) => const Text('Students Content'),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const Text('Settings Content'),
              ),
              GoRoute(
                path: '/attendance/qr-scan',
                builder: (context, state) => const Text('QR Scanner Screen'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ops'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Scan shortcut has scanner icon
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);

      // Tapping Events navigates to events screen
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();
      expect(find.text('Events Content'), findsOneWidget);
    });
  });
}

