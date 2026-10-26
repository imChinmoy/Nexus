import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';
import 'package:brl_nexus/features/events/domain/repositories/event_repository.dart';
import 'package:brl_nexus/features/events/presentation/screens/edit_event_screen.dart';
import 'package:brl_nexus/features/events/providers/event_provider.dart';

class MockEventRepository implements EventRepository {
  EventEntity? updatedEvent;
  String? updatedId;
  String? updatedTitle;
  int? updatedCapacity;
  String? updatedVenue;
  String? updatedType;
  String? updatedStatus;
  bool? updatedIsAttendanceOpen;
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
    String? status,
    bool? isAttendanceOpen,
  }) async {
    if (shouldFail) {
      return const Left(ServerFailure('Failed to update event'));
    }

    updatedId = id;
    updatedTitle = title;
    updatedCapacity = capacity;
    updatedVenue = venue;
    updatedType = type;
    updatedStatus = status;
    updatedIsAttendanceOpen = isAttendanceOpen;

    final event = EventEntity(
      id: id,
      title: title ?? 'Updated Title',
      description: description,
      venue: venue,
      startDate: startDate ?? DateTime(2026, 10, 24),
      endDate: endDate ?? DateTime(2026, 10, 27),
      type: type ?? 'seminar',
      capacity: capacity ?? 150,
      status: status ?? 'ongoing',
      isAttendanceOpen: isAttendanceOpen ?? true,
    );
    updatedEvent = event;
    return Right(event);
  }

  @override
  Future<Either<Failure, EventEntity>> toggleAttendance(String id, bool isOpen) async =>
      throw UnimplementedError();
}

void main() {
  final testEvent = EventEntity(
    id: 'event-edit-1',
    title: 'Expert Seminar 2026',
    description: 'AI & Web3 Seminar by industry leaders and research mentors.',
    venue: 'Seminar Hall 2',
    banner: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
    startDate: DateTime(2026, 10, 24),
    endDate: DateTime(2026, 10, 27),
    type: 'seminar',
    capacity: 150,
    status: 'upcoming',
    isAttendanceOpen: false,
  );

  Widget createEditEventScreenHarness({
    required EventEntity event,
    required MockEventRepository repository,
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: EditEventScreen(event: event),
      ),
    );
  }

  group('EditEventScreen — Multi-Step Stepper & Form Control Tests', () {
    testWidgets('Prepopulates existing event data on Step 0 (Basic Info)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Header shows Edit Event and event title
      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Expert Seminar 2026'), findsWidgets);

      // Stepper shows 4 steps
      expect(find.text('Basic Info'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Step 0 fields are visible and prepopulated
      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_description_field')), findsOneWidget);
      expect(find.text('Change Banner'), findsOneWidget);

      // Step 1 fields are NOT visible on Step 0
      expect(find.byKey(const ValueKey('edit_event_type_dropdown')), findsNothing);
      expect(find.byKey(const ValueKey('edit_event_capacity_field')), findsNothing);

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
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // --- STEP 0 -> STEP 1 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 1: Details
      expect(find.byKey(const ValueKey('edit_event_type_dropdown')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_capacity_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_venue_field')), findsOneWidget);
      expect(find.text('150'), findsOneWidget); // Prepopulated capacity
      expect(find.text('Seminar Hall 2'), findsOneWidget); // Prepopulated venue
      expect(find.byKey(const ValueKey('step_back_button')), findsOneWidget);
      expect(find.text('Next: Schedule'), findsOneWidget);

      // --- STEP 1 -> STEP 2 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 2: Schedule
      expect(find.byKey(const ValueKey('edit_event_start_date_tile')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_end_date_tile')), findsOneWidget);
      expect(find.text('Oct 24, 2026'), findsOneWidget);
      expect(find.text('Oct 27, 2026'), findsOneWidget);
      expect(find.text('Next: Settings'), findsOneWidget);

      // --- STEP 2 -> STEP 3 ---
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Now on Step 3: Settings
      expect(find.text('Status & Attendance'), findsOneWidget);
      expect(find.byKey(const ValueKey('status_pill_upcoming')), findsOneWidget);
      expect(find.byKey(const ValueKey('status_pill_ongoing')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_attendance_switch')), findsOneWidget);
      expect(find.text('Configuration Review'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // --- STEP 3 -> STEP 2 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_event_start_date_tile')), findsOneWidget);

      // --- STEP 2 -> STEP 1 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_event_type_dropdown')), findsOneWidget);

      // --- STEP 1 -> STEP 0 (Back) ---
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('step_back_button')), findsNothing);
    });

    testWidgets('Stepper progress nodes allow direct tapping and show completion checkmarks',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Tap Step 2 node directly (all prior steps are valid)
      await tester.tap(find.byKey(const ValueKey('step_node_2')));
      await tester.pumpAndSettle();

      // Should jump directly to Schedule
      expect(find.byKey(const ValueKey('edit_event_start_date_tile')), findsOneWidget);

      // Past nodes (0 and 1) should show checkmarks
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));

      // Tap Step 0 node directly to return
      await tester.tap(find.byKey(const ValueKey('step_node_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);
    });

    testWidgets('Validation prevents moving forward when required fields are invalid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Clear the event title on Step 0
      await tester.enterText(find.byKey(const ValueKey('edit_event_title_field')), '');
      await tester.pumpAndSettle();

      // Try tapping Next
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Should still be on Step 0 and display error message
      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);
      expect(find.text('Event title is required'), findsWidgets);

      // Enter valid title
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_title_field')), 'Valid Seminar Title');
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).clearSnackBars();
      await tester.pumpAndSettle();

      // Advance to Step 1
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_event_capacity_field')), findsOneWidget);

      // Enter invalid capacity (0 or negative)
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_capacity_field')), '0');
      await tester.pumpAndSettle();

      // Try tapping Next
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Should remain on Step 1 with error
      expect(find.byKey(const ValueKey('edit_event_capacity_field')), findsOneWidget);
      expect(find.text('Valid positive capacity is required'), findsWidgets);
    });

    testWidgets('Preserves form state and user edits across step transitions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Modify Title and Description on Step 0
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_title_field')), 'Custom Edited Seminar');
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_description_field')), 'New Custom Description');
      await tester.pumpAndSettle();

      // Advance to Step 1
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Modify Capacity and Venue on Step 1
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_capacity_field')), '250');
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_venue_field')), 'New Auditorium Hall');
      await tester.pumpAndSettle();

      // Advance to Step 2 then Step 3
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // On Step 3: Verify the configuration review reflects the modified values
      expect(find.text('Custom Edited Seminar'), findsOneWidget);
      expect(find.text('New Custom Description'), findsOneWidget);
      expect(find.text('250 Capacity'), findsOneWidget);
      expect(find.text('New Auditorium Hall'), findsOneWidget);

      // Go all the way back to Step 0
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('step_back_button')));
      await tester.pumpAndSettle();

      // Verify Step 0 still holds the modified values
      expect(find.text('Custom Edited Seminar'), findsOneWidget);
      expect(find.text('New Custom Description'), findsOneWidget);
    });

    testWidgets('Final submission successfully updates event via repository with all modified fields',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Modify Title
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_title_field')), 'Updated Seminar Title');
      await tester.pumpAndSettle();

      // Jump to Step 3 directly
      await tester.tap(find.byKey(const ValueKey('step_node_3')));
      await tester.pumpAndSettle();

      // Change status to ongoing
      await tester.tap(find.byKey(const ValueKey('status_pill_ongoing')));
      await tester.pumpAndSettle();

      // Enable Live Attendance switch
      await tester.tap(find.byKey(const ValueKey('edit_event_attendance_switch')));
      await tester.pumpAndSettle();

      // Submit via Save Changes button
      await tester.tap(find.byKey(const ValueKey('step_save_button')));
      await tester.pump(); // Start async submit

      expect(repo.updatedId, 'event-edit-1');
      expect(repo.updatedTitle, 'Updated Seminar Title');
      expect(repo.updatedStatus, 'ongoing');
      expect(repo.updatedIsAttendanceOpen, true);
    });

    testWidgets('Top AppBar Save button validates and submits from any step',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // On Step 0: edit title
      await tester.enterText(
          find.byKey(const ValueKey('edit_event_title_field')), 'Quick Saved Title');
      await tester.pumpAndSettle();

      // Tap Top AppBar Save button directly from Step 0
      await tester.tap(find.byKey(const ValueKey('top_save_button')));
      await tester.pump();

      // Repository updateEvent should have been invoked with the new title
      expect(repo.updatedId, 'event-edit-1');
      expect(repo.updatedTitle, 'Quick Saved Title');
    });

    testWidgets('Top AppBar back arrow goes to previous step when activeStep > 0',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: testEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Advance to Step 1
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('edit_event_type_dropdown')), findsOneWidget);

      // Tap top AppBar back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Should return to Step 0
      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);
    });

    testWidgets(
        'Handles recruitment event type and 741+ character description without dropdown crash or overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const longDesc =
          'Or Register directly at https://brl.akgec.ac.in/reload\n'
          'Don\'t miss your chance to be part of something exciting. Join our community '
          'of developers, researchers, and innovators working on next-generation decentralized '
          'protocols, smart contract auditing, and zero-knowledge systems.\n\n'
          'Reload 26 is the premier annual recruitment and technical induction challenge '
          'for students across campus. Participants will undergo rigorous evaluation across '
          'algorithmic problem solving, systems engineering, cryptography fundamentals, '
          'and web3 architecture. Outstanding candidates will be awarded direct mentorship '
          'and research grants for prospective lab members.';

      final recruitmentEvent = EventEntity(
        id: 'reload-26',
        title: 'Reload 26, Recruitment Drive',
        description: longDesc,
        venue: 'Main Auditorium',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 3),
        type: 'recruitment',
        capacity: 300,
        status: 'upcoming',
        isAttendanceOpen: false,
      );

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: recruitmentEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Step 0: verify description counter shows /2000 and the long description text
      expect(find.text('${longDesc.length}/2000'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_event_title_field')), findsOneWidget);

      // Tap Next to navigate to Step 1 (Details)
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Must find the Dropdown with recruitment value without throwing assertion error
      final dropdownFinder = find.byKey(const ValueKey('edit_event_type_dropdown'));
      expect(dropdownFinder, findsOneWidget);
      final dropdownWidget = tester.widget<DropdownButton<String>>(dropdownFinder);
      expect(dropdownWidget.value, 'recruitment');
    });

    testWidgets(
        'Safely adds unknown/custom event type to dropdown items dynamically',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customEvent = EventEntity(
        id: 'custom-event-1',
        title: 'AI Summit 2026',
        description: 'Global AI Summit',
        venue: 'Virtual',
        startDate: DateTime(2026, 12, 1),
        endDate: DateTime(2026, 12, 2),
        type: 'ai-summit',
        capacity: 500,
        status: 'upcoming',
        isAttendanceOpen: false,
      );

      final repo = MockEventRepository();
      await tester.pumpWidget(createEditEventScreenHarness(
        event: customEvent,
        repository: repo,
      ));
      await tester.pumpAndSettle();

      // Navigate to Step 1 (Details)
      await tester.tap(find.byKey(const ValueKey('step_next_button')));
      await tester.pumpAndSettle();

      // Dropdown should not crash and should contain 'ai-summit'
      final dropdownFinder = find.byKey(const ValueKey('edit_event_type_dropdown'));
      expect(dropdownFinder, findsOneWidget);
      final dropdownWidget = tester.widget<DropdownButton<String>>(dropdownFinder);
      expect(dropdownWidget.value, 'ai-summit');
      expect(
        dropdownWidget.items!.any((item) => item.value == 'ai-summit'),
        isTrue,
      );
    });
  });
}

