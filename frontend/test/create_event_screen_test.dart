import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';
import 'package:brl_nexus/features/events/domain/repositories/event_repository.dart';
import 'package:brl_nexus/features/events/presentation/screens/create_event_screen.dart';
import 'package:brl_nexus/features/events/providers/event_provider.dart';

class MockEventRepository implements EventRepository {
  EventEntity? createdEvent;
  String? createdTitle;
  int? createdCapacity;
  String? createdVenue;
  String? createdType;
  DateTime? createdStartDate;
  DateTime? createdEndDate;
  String? createdDescription;
  bool shouldFail = false;

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents() async {
    return const Right([]);
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
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Failed to create event'));
    }

    createdTitle = title;
    createdCapacity = capacity;
    createdVenue = venue;
    createdType = type;
    createdStartDate = startDate;
    createdEndDate = endDate;
    createdDescription = description;

    final event = EventEntity(
      id: 'event-created-1',
      title: title,
      description: description,
      venue: venue,
      startDate: startDate,
      endDate: endDate,
      type: type,
      capacity: capacity,
      status: 'upcoming',
      isAttendanceOpen: false,
    );
    createdEvent = event;
    return Right(event);
  }

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
    String? status,
    bool? isAttendanceOpen,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, EventEntity>> toggleAttendance(String id, bool isOpen) async =>
      throw UnimplementedError();
}

void main() {
  Widget createCreateEventScreenHarness({
    required MockEventRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: CreateEventScreen(),
      ),
    );
  }

  group('CreateEventScreen — Multi-Step Stepper & Progress Tracker Tests', () {
    testWidgets('Renders Step 0 (Basic Info) initially with 4-step progress tracker',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Header shows New Event
      expect(find.text('New Event'), findsOneWidget);

      // Stepper shows 4 steps
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      // Step 0 fields are visible
      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_description_field')), findsOneWidget);
      expect(find.text('Upload Event Banner'), findsOneWidget);

      // Step 1 fields are NOT visible on Step 0
      expect(find.byKey(const ValueKey('create_event_type_dropdown')), findsNothing);
      expect(find.byKey(const ValueKey('create_event_capacity_field')), findsNothing);

      // Bottom button shows Next: Details
      expect(find.text('Next: Details'), findsOneWidget);
      expect(find.byKey(const ValueKey('step_back_button')), findsNothing);
    });

    testWidgets('Navigates sequentially through all 4 steps using Next & Back buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Enter title on Step 0
      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'Full Stack Hackathon 2026');
      await tester.enterText(
          find.byKey(const ValueKey('create_event_description_field')), '48-hour buildathon for university devs');
      await tester.pumpAndSettle();

      // --- STEP 0 -> STEP 1 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 1: Details
      expect(find.byKey(const ValueKey('create_event_type_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_capacity_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_venue_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('step_back_button')), findsOneWidget);
      expect(find.text('Next: Schedule'), findsOneWidget);

      // Enter venue on Step 1
      await tester.enterText(
          find.byKey(const ValueKey('create_event_venue_field')), 'Innovation Center Lab 4');
      await tester.pumpAndSettle();

      // --- STEP 1 -> STEP 2 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 2: Schedule
      expect(find.byKey(const ValueKey('create_event_start_date_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_end_date_tile')), findsOneWidget);
      expect(find.text('Next: Review'), findsOneWidget);

      // --- STEP 2 -> STEP 3 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 3: Review
      expect(find.text('Ready to Launch Event'), findsOneWidget);
      expect(find.text('Configuration Summary'), findsOneWidget);
      expect(find.text('Full Stack Hackathon 2026'), findsWidgets);
      expect(find.text('Create Event'), findsOneWidget);
      expect(find.byKey(const ValueKey('step_create_button')), findsOneWidget);

      // --- STEP 3 -> STEP 2 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_start_date_tile')), findsOneWidget);
      expect(find.text('Next: Review'), findsOneWidget);

      // --- STEP 2 -> STEP 1 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_venue_field')), findsOneWidget);
      expect(find.text('Innovation Center Lab 4'), findsOneWidget); // Preserves input

      // --- STEP 1 -> STEP 0 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);
      expect(find.text('Full Stack Hackathon 2026'), findsOneWidget); // Preserves input
      expect(find.byKey(const ValueKey('step_back_button')), findsNothing);
    });

    testWidgets('Validation prevents moving forward when required fields are invalid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Attempt to advance on Step 0 without entering title
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Should show error and remain on Step 0
      expect(find.text('Event title is required'), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();

      // Enter short title (< 3 chars)
      await tester.enterText(find.byKey(const ValueKey('create_event_title_field')), 'AB');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Event title must be at least 3 characters'), findsOneWidget);

      // Dismiss snackbar
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();

      // Enter valid title and advance to Step 1
      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'Robotics Workshop');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_capacity_field')), findsOneWidget);

      // Clear capacity
      await tester.enterText(find.byKey(const ValueKey('create_event_capacity_field')), '');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      expect(find.text('Valid positive capacity is required'), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_capacity_field')), findsOneWidget);
    });

    testWidgets('Direct progress tracker node taps allow backward navigation and validate forward skips',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Tapping node 2 directly from step 0 with empty title fails validation and stays on step 0
      await tester.tap(find.byKey(const ValueKey('step_node_2')));
      await tester.pumpAndSettle();

      expect(find.text('Event title is required'), findsOneWidget);
      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);

      // Fill valid title and advance to step 1
      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'Cloud Native Summit');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_node_1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_type_dropdown')), findsOneWidget);

      // Tap backward to node 0 directly
      await tester.tap(find.byKey(const ValueKey('step_node_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);
      expect(find.text('Cloud Native Summit'), findsOneWidget);
    });

    testWidgets('Submitting on Step 3 successfully creates event via repository',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Step 0: Basic Info
      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'AI in Healthcare Conference');
      await tester.enterText(
          find.byKey(const ValueKey('create_event_description_field')), 'Symposium on ML applications in clinical care');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Step 1: Details
      await tester.enterText(
          find.byKey(const ValueKey('create_event_capacity_field')), '350');
      await tester.enterText(
          find.byKey(const ValueKey('create_event_venue_field')), 'Main Auditorium');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Step 2: Schedule
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Step 3: Review -> Submit
      expect(find.text('Create Event'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('step_create_button')));
      await tester.pumpAndSettle();

      expect(repo.createdTitle, 'AI in Healthcare Conference');
      expect(repo.createdCapacity, 350);
      expect(repo.createdVenue, 'Main Auditorium');
      expect(repo.createdDescription, 'Symposium on ML applications in clinical care');
    });

    testWidgets('Top AppBar Create button validates and submits from any step when valid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Fill Step 0
      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'Design Systems Workshop');
      await tester.pumpAndSettle();

      // Tap Top Create action directly from Step 0
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Event is created because default capacity, schedule, and type are valid
      expect(repo.createdTitle, 'Design Systems Workshop');
      expect(repo.createdCapacity, 500); // Default capacity
    });

    testWidgets('Top AppBar back arrow goes to previous step when activeStep > 0',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createCreateEventScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const ValueKey('create_event_title_field')), 'Cybersecurity Seminar');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('create_event_capacity_field')), findsOneWidget);

      // Tap Top Back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Should return to Step 0
      expect(find.byKey(const ValueKey('create_event_title_field')), findsOneWidget);
    });
  });
}
