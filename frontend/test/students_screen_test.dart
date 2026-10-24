import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/exceptions.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';
import 'package:brl_nexus/features/events/domain/repositories/event_repository.dart';
import 'package:brl_nexus/features/events/providers/event_provider.dart';
import 'package:brl_nexus/features/students/data/models/student_model.dart';
import 'package:brl_nexus/features/students/data/repositories/student_repository_impl.dart';
import 'package:brl_nexus/features/students/data/sources/student_remote_source.dart';
import 'package:brl_nexus/features/students/presentation/screens/students_screen.dart';
import 'package:brl_nexus/features/students/providers/student_provider.dart';

class MockEventRepository implements EventRepository {
  final List<EventEntity> mockEvents = [
    EventEntity(
      id: 'event-1',
      title: 'Expert Seminar 2026',
      startDate: DateTime(2026, 10, 24, 10, 0),
      endDate: DateTime(2026, 10, 24, 12, 0),
      type: 'seminar',
      capacity: 100,
      status: 'ongoing',
      isAttendanceOpen: true,
    ),
    EventEntity(
      id: 'event-2',
      title: 'Reload Hackathon',
      startDate: DateTime(2026, 11, 1, 9, 0),
      endDate: DateTime(2026, 11, 2, 17, 0),
      type: 'hackathon',
      capacity: 200,
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
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? capacity,
    String? description,
    String? venue,
    String? bannerPath,
    String? status,
    bool? isAttendanceOpen,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, EventEntity>> toggleAttendance(String id, bool isOpen) async =>
      throw UnimplementedError();
}

class MockStudentRemoteSource implements StudentRemoteSource {
  bool shouldThrowError = false;
  String errorMessage = 'Registration source is not configured for this event';
  String? lastFetchedEventId;
  String? lastSearch;
  String? lastBranch;
  String? lastAttendanceStatus;
  int lastPage = 1;

  final Map<String, List<StudentModel>> eventData = {
    'event-1': [
      StudentModel(
        id: 's1',
        name: 'Alice Sharma',
        rollNumber: '240027100001',
        studentNo: '2410001',
        branch: 'CSE',
        year: 2,
        email: 'alice@test.com',
        attendanceStatus: 'present',
        isPresent: true,
        markedAt: DateTime(2026, 10, 24, 10, 15),
      ),
      const StudentModel(
        id: 's2',
        name: 'Bob Verma',
        rollNumber: '240027100002',
        studentNo: '2410002',
        branch: 'IT',
        year: 2,
        email: 'bob@test.com',
        attendanceStatus: null, // Not marked
        isPresent: false,
      ),
    ],
    'event-2': [
      const StudentModel(
        id: 's3',
        name: 'David Miller',
        rollNumber: '240027100004',
        studentNo: '2410004',
        branch: 'ECE',
        year: 3,
        email: 'david@test.com',
        attendanceStatus: null,
        isPresent: false,
      ),
    ],
  };

  @override
  Future<EventStudentsResultModel> getStudentsByEvent(
    String eventId, {
    int page = 1,
    int limit = 20,
    String? search,
    String? branch,
    String? attendanceStatus,
  }) async {
    lastFetchedEventId = eventId;
    lastSearch = search;
    lastBranch = branch;
    lastAttendanceStatus = attendanceStatus;
    lastPage = page;

    if (shouldThrowError) {
      throw ServerException(errorMessage);
    }

    final all = eventData[eventId] ?? [];
    var filtered = List<StudentModel>.from(all);

    if (search != null && search.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name.toLowerCase().contains(search.toLowerCase()) || s.rollNumber.contains(search))
          .toList();
    }
    if (branch != null && branch != 'All') {
      filtered = filtered.where((s) => s.branch == branch).toList();
    }
    if (attendanceStatus != null && attendanceStatus != 'All') {
      if (attendanceStatus == 'not_marked') {
        filtered = filtered.where((s) => s.attendanceStatus == null).toList();
      } else {
        filtered = filtered.where((s) => s.attendanceStatus == attendanceStatus).toList();
      }
    }

    final presentCount = all.where((s) => s.attendanceStatus == 'present').length;
    final notMarkedCount = all.where((s) => s.attendanceStatus == null).length;

    return EventStudentsResultModel(
      students: filtered,
      total: filtered.length,
      page: page,
      limit: limit,
      totalPages: 1,
      counts: EventStudentCountsModel(
        total: all.length,
        present: presentCount,
        notMarked: notMarkedCount,
      ),
    );
  }

  @override
  Future<List<StudentModel>> getStudents({String? search}) async {
    return eventData['event-1'] ?? [];
  }

  @override
  Future<StudentModel> createStudent({
    required String name,
    required String rollNumber,
    required String branch,
    required int year,
    required String email,
    required String phone,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  late MockEventRepository mockEventRepo;
  late MockStudentRemoteSource mockStudentRemote;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockStudentRemote = MockStudentRemoteSource();
  });

  Widget createWidgetUnderTest({String? initialEventId, ThemeMode themeMode = ThemeMode.dark}) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepo),
        studentRepositoryProvider.overrideWithValue(StudentRepositoryImpl(mockStudentRemote)),
        if (initialEventId != null)
          selectedEventIdProvider.overrideWith((ref) => initialEventId),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: const StudentsScreen(),
      ),
    );
  }

  group('StudentsScreen Widget Tests', () {
    testWidgets('Displays initial guide state when no events exist in repository', (tester) async {
      mockEventRepo.mockEvents.clear();
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header shows selector placeholder
      expect(find.text('Select an Event to View Students'), findsOneWidget);
      // Main area shows initial guide
      expect(find.text('Select an Event'), findsOneWidget);
      expect(find.text('CHOOSE EVENT'), findsOneWidget);
    });

    testWidgets('Automatically defaults to ongoing or closest upcoming event and loads registrations', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Automatically selected Expert Seminar 2026 (ongoing)
      expect(find.text('Expert Seminar 2026'), findsOneWidget);
      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('Bob Verma'), findsOneWidget);
      expect(find.text('David Miller'), findsNothing);
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Not Scanned'), findsWidgets);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('Tapping event card opens bottom sheet with events sorted chronologically and allows switching', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Expert Seminar 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Select Event'), findsOneWidget);
      expect(find.text('Expert Seminar 2026'), findsWidgets);
      expect(find.text('Reload Hackathon'), findsOneWidget);

      // Select Reload Hackathon
      await tester.tap(find.text('Reload Hackathon'));
      await tester.pumpAndSettle();

      expect(find.text('Reload Hackathon'), findsOneWidget);
      expect(find.text('David Miller'), findsOneWidget);
      expect(find.text('Alice Sharma'), findsNothing);
    });

    testWidgets('Switching events switches the registrations dataset and resets filters', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1'));
      await tester.pumpAndSettle();

      // Event 1 students visible
      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('David Miller'), findsNothing);

      // Open event selector and switch to Reload Hackathon (event 2)
      await tester.tap(find.text('Expert Seminar 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reload Hackathon'));
      await tester.pumpAndSettle();

      // Now Event 2 students are visible
      expect(find.text('David Miller'), findsOneWidget);
      expect(find.text('Alice Sharma'), findsNothing);
      expect(find.text('Bob Verma'), findsNothing);
    });

    testWidgets('Registration source error displays error state, not empty registration list', (tester) async {
      mockStudentRemote.shouldThrowError = true;
      mockStudentRemote.errorMessage = 'Registration source is not configured for this event';

      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1'));
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Registrations'), findsOneWidget);
      expect(find.text('Registration source is not configured for this event'), findsOneWidget);
      expect(find.text('RETRY'), findsOneWidget);
      // Must NOT show 0 registered students empty state
      expect(find.text('No Students Registered'), findsNothing);
    });

    testWidgets('Theme switching works cleanly on Students screen in light and dark mode', (tester) async {
      // Light theme
      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1', themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      expect(find.text('Alice Sharma'), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1', themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(find.text('Alice Sharma'), findsOneWidget);
    });

    testWidgets('Handles narrow screen widths without clipping or overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 600 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Reset physical size
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Primary segmented attendance filters toggle attendance state cleanly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1'));
      await tester.pumpAndSettle();

      // Initially 'All' is active, both students visible
      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('Bob Verma'), findsOneWidget);

      // Tap 'Present' segmented option
      await tester.tap(find.text('Present').first);
      await tester.pumpAndSettle();

      expect(mockStudentRemote.lastAttendanceStatus, 'present');
      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('Bob Verma'), findsNothing);

      // Tap 'Not Scanned' segmented option
      await tester.tap(find.text('Not Scanned').first);
      await tester.pumpAndSettle();

      expect(mockStudentRemote.lastAttendanceStatus, 'not_marked');
      expect(find.text('Bob Verma'), findsOneWidget);
      expect(find.text('Alice Sharma'), findsNothing);

      // Tap 'All' segmented option
      await tester.tap(find.text('All').first);
      await tester.pumpAndSettle();

      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('Bob Verma'), findsOneWidget);
    });

    testWidgets('Secondary filters sheet allows filtering by branch with active badge indicator', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(initialEventId: 'event-1'));
      await tester.pumpAndSettle();

      // Open secondary filters sheet via filter icon button
      await tester.tap(find.byTooltip('Filter Students'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Students'), findsOneWidget);
      expect(find.text('ACADEMIC BRANCH'), findsOneWidget);
      expect(find.text('ATTENDANCE STATUS'), findsOneWidget);

      // Tap 'CSE' branch chip in filter sheet
      await tester.tap(find.text('CSE').last);
      await tester.pumpAndSettle();

      // Tap 'Apply Filters'
      await tester.tap(find.text('Apply Filters'));
      await tester.pumpAndSettle();

      // Results filtered by branch CSE
      expect(mockStudentRemote.lastBranch, 'CSE');
      expect(find.text('Alice Sharma'), findsOneWidget);
      expect(find.text('Bob Verma'), findsNothing);
    });
  });
}
