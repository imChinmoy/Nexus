import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';
import 'package:brl_nexus/features/events/domain/repositories/event_repository.dart';
import 'package:brl_nexus/features/events/presentation/screens/events_screen.dart';
import 'package:brl_nexus/features/events/presentation/widgets/event_deck_card.dart';
import 'package:brl_nexus/features/events/presentation/widgets/event_filter_bar.dart';
import 'package:brl_nexus/features/events/presentation/widgets/event_swipe_deck.dart';
import 'package:brl_nexus/features/events/providers/event_provider.dart';
import 'package:brl_nexus/shared/widgets/empty_state_widget.dart';

class MockEventRepository implements EventRepository {
  List<EventEntity> mockEvents;

  MockEventRepository({List<EventEntity>? events})
      : mockEvents = events ??
            [
              EventEntity(
                id: 'event-ongoing-1',
                title: 'Global Web3 Hackathon 2026',
                description:
                    'Collaborative blockchain hackathon with international mentors',
                venue: 'Innovation Hub, Hall A',
                banner: 'https://example.com/hackathon.jpg',
                startDate: DateTime.now().subtract(const Duration(hours: 2)),
                endDate: DateTime.now().add(const Duration(hours: 6)),
                type: 'hackathon',
                capacity: 200,
                status: 'ongoing',
                isAttendanceOpen: true,
              ),
              EventEntity(
                id: 'event-upcoming-2',
                title: 'Smart Contract Security Seminar',
                description:
                    'Deep dive into formal verification and EVM security models',
                venue: 'Auditorium 2',
                banner: 'https://example.com/security.jpg',
                startDate: DateTime.now().add(const Duration(days: 3)),
                endDate: DateTime.now().add(const Duration(days: 3, hours: 4)),
                type: 'seminar',
                capacity: 100,
                status: 'upcoming',
                isAttendanceOpen: false,
              ),
              EventEntity(
                id: 'event-completed-3',
                title: 'DeFi Architecture Workshop',
                description: 'Hands-on AMM and liquidity protocols workshop',
                venue: 'Computer Center Lab 3',
                banner: '', // Test fallback banner
                startDate: DateTime.now().subtract(const Duration(days: 5)),
                endDate: DateTime.now().subtract(const Duration(days: 4)),
                type: 'workshop',
                capacity: 80,
                status: 'completed',
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
  }) async {
    final newEvent = EventEntity(
      id: 'event-new-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      startDate: startDate,
      endDate: endDate,
      type: type,
      capacity: capacity,
      description: description,
      venue: venue,
      banner: bannerPath,
      status: 'upcoming',
    );
    mockEvents.add(newEvent);
    return Right(newEvent);
  }

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
  }) async {
    final idx = mockEvents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = mockEvents[idx].copyWith(
        title: title,
        startDate: startDate,
        endDate: endDate,
        type: type,
        capacity: capacity,
        description: description,
        venue: venue,
        banner: bannerPath,
        status: status,
        isAttendanceOpen: isAttendanceOpen,
      );
      mockEvents[idx] = updated;
      return Right(updated);
    }
    return const Left(ServerFailure('Event not found'));
  }

  @override
  Future<Either<Failure, EventEntity>> toggleAttendance(
      String id, bool isOpen) async {
    final idx = mockEvents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final updated = mockEvents[idx].copyWith(isAttendanceOpen: isOpen);
      mockEvents[idx] = updated;
      return Right(updated);
    }
    return const Left(ServerFailure('Event not found'));
  }
}

final testAdminUser = UserEntity(
  id: 'user-admin-1',
  name: 'Admin User',
  email: 'admin@brlnexus.com',
  role: UserRole.superAdmin,
  isActive: true,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

Widget createEventsScreenHarness({
  required MockEventRepository repository,
  UserEntity? user,
  List<String> permissions = const ['all'],
  ThemeMode themeMode = ThemeMode.dark,
  Size screenSize = const Size(400, 840),
  bool disableAnimations = false,
}) {
  return ProviderScope(
    overrides: [
      eventRepositoryProvider.overrideWithValue(repository),
      currentUserProvider.overrideWith((ref) => user ?? testAdminUser),
      myPermissionsProvider.overrideWith((ref) => permissions),
    ],
    child: MaterialApp(
      themeMode: themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          disableAnimations: disableAnimations,
        ),
        child: const EventsScreen(),
      ),
    ),
  );
}

void main() {
  group('Event Timeline Status and Sync Logic (Frontend Unit Tests)', () {
    test('Calculates upcoming status correctly for future events', () {
      final baseTime = DateTime(2026, 10, 24, 12, 0);
      final event = EventEntity(
        id: '1',
        title: 'Future Summit',
        startDate: DateTime(2026, 10, 25, 10, 0),
        endDate: DateTime(2026, 10, 25, 18, 0),
        type: 'summit',
        capacity: 100,
        status: 'upcoming',
      );

      expect(event.effectiveStatusAt(baseTime), 'upcoming');
      expect(event.isPastAt(baseTime), false);
      expect(event.matchesFilter('upcoming', baseTime), true);
      expect(event.matchesFilter('ongoing', baseTime), false);
      expect(event.matchesFilter('ended', baseTime), false);
    });

    test(
        'Calculates ongoing status correctly when clock is within start and end boundaries',
        () {
      final baseTime = DateTime(2026, 10, 24, 14, 0);
      final event = EventEntity(
        id: '2',
        title: 'Active Workshop',
        startDate: DateTime(2026, 10, 24, 10, 0),
        endDate: DateTime(2026, 10, 24, 16, 0),
        type: 'workshop',
        capacity: 50,
        status: 'upcoming', // Stale stored status in DB
      );

      // Stale stored 'upcoming' must be reconciled to 'ongoing'
      expect(event.effectiveStatusAt(baseTime), 'ongoing');
      expect(event.isPastAt(baseTime), false);
      expect(event.matchesFilter('ongoing', baseTime), true);
      expect(event.matchesFilter('upcoming', baseTime), false);
    });

    test(
        'Calculates completed status for expired events even if stored status is stale upcoming or ongoing',
        () {
      final baseTime = DateTime(2026, 10, 24, 18, 0);
      final event = EventEntity(
        id: '3',
        title: 'Expired Hackathon',
        startDate: DateTime(2026, 10, 24, 9, 0),
        endDate: DateTime(2026, 10, 24, 16, 0),
        type: 'hackathon',
        capacity: 150,
        status: 'ongoing', // Stale stored status
      );

      expect(event.effectiveStatusAt(baseTime), 'completed');
      expect(event.isPastAt(baseTime), true);
      expect(event.matchesFilter('ended', baseTime), true);
      expect(event.matchesFilter('completed', baseTime), true);
      expect(event.matchesFilter('ongoing', baseTime), false);
    });

    test(
        'Treats date-only event ending date as inclusive of that full local day',
        () {
      // Event on Oct 24 date-only (00:00:00)
      final dateOnlyEvent = EventEntity(
        id: '4',
        title: 'Campus Orientation',
        startDate: DateTime(2026, 10, 24, 0, 0, 0),
        endDate: DateTime(2026, 10, 24, 0, 0, 0),
        type: 'recruitment',
        capacity: 300,
        status: 'upcoming',
      );

      // At 3:00 PM on Oct 24, the date-only event is ongoing, NOT ended
      final afternoon = DateTime(2026, 10, 24, 15, 0, 0);
      expect(dateOnlyEvent.effectiveStatusAt(afternoon), 'ongoing');
      expect(dateOnlyEvent.isPastAt(afternoon), false);

      // On Oct 25 morning, the date-only event is completed
      final nextDay = DateTime(2026, 10, 25, 8, 0, 0);
      expect(dateOnlyEvent.effectiveStatusAt(nextDay), 'completed');
      expect(dateOnlyEvent.isPastAt(nextDay), true);
    });

    test(
        'Preserves explicit cancelled and archived states even when dates are in future',
        () {
      final baseTime = DateTime(2026, 10, 24, 12, 0);
      final cancelledEvent = EventEntity(
        id: '5',
        title: 'Cancelled Meetup',
        startDate: DateTime(2026, 10, 28, 10, 0),
        endDate: DateTime(2026, 10, 28, 12, 0),
        type: 'meeting',
        capacity: 40,
        status: 'cancelled',
      );

      expect(cancelledEvent.effectiveStatusAt(baseTime), 'cancelled');
      expect(cancelledEvent.matchesFilter('cancelled', baseTime), true);
      expect(cancelledEvent.matchesFilter('upcoming', baseTime), false);

      final archivedEvent = EventEntity(
        id: '6',
        title: 'Archived Assembly',
        startDate: DateTime(2026, 10, 30, 10, 0),
        endDate: DateTime(2026, 10, 30, 12, 0),
        type: 'meeting',
        capacity: 40,
        status: 'archived',
      );

      expect(archivedEvent.effectiveStatusAt(baseTime), 'archived');
      expect(archivedEvent.matchesFilter('archived', baseTime), true);
      expect(archivedEvent.matchesFilter('upcoming', baseTime), false);
    });
  });

  group('EventsScreen Swipeable Event Deck UI/UX Tests', () {
    testWidgets(
        'Renders dominant active card in center with title, status, and background stack cards',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Top active card is visible
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(find.text('ONGOING'), findsWidgets);
      expect(find.text('HACKATHON'), findsWidgets);
      expect(find.text('Innovation Hub, Hall A'), findsOneWidget);

      // Background cards in stack exist
      expect(find.byType(EventDeckCard), findsWidgets);
      expect(find.byType(EventSwipeDeck), findsOneWidget);

      // Deck navigation indicator shows "01 / 03"
      expect(find.text('01'), findsOneWidget);
      expect(find.text(' / 03'), findsOneWidget);
      expect(find.text('Swipe Deck'), findsOneWidget);

      // Accessible controls exist
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('Swiping active card right advances deck to next event',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);

      // Drag right across threshold
      final activeCard = find.text('Global Web3 Hackathon 2026');
      await tester.drag(activeCard, const Offset(200, 0));
      await tester.pumpAndSettle();

      // Now event 2 is active
      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text(' / 03'), findsOneWidget);
    });

    testWidgets('Swiping active card left returns to previous event',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Advance to 2nd card
      await tester.drag(
          find.text('Global Web3 Hackathon 2026'), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);

      // Drag left across threshold
      await tester.drag(
          find.text('Smart Contract Security Seminar'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      // Returns to event 1
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets(
        'Incomplete drag below gesture threshold springs back to resting position without changing index',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);

      // Drag by only 20px (well below threshold) and release
      await tester.drag(
          find.text('Global Web3 Hackathon 2026'), const Offset(20, 0));
      await tester.pumpAndSettle();

      // Index remains at 0, active card is unchanged
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets(
        'Gracefully handles deck boundaries at first event and last event',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // At index 0, attempt to drag left (previous)
      await tester.drag(
          find.text('Global Web3 Hackathon 2026'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      // Remains at first event
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);

      // Advance to last event (event 3)
      final nextBtn = find.byIcon(Icons.chevron_right_rounded);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(find.text('DeFi Architecture Workshop'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);

      // At last index, drag right (next)
      await tester.drag(
          find.text('DeFi Architecture Workshop'), const Offset(150, 0));
      await tester.pumpAndSettle();

      // Remains safely at last event without error
      expect(find.text('DeFi Architecture Workshop'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets('Accessible Previous and Next buttons navigate deck smoothly',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);

      // Tap Previous button
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
    });

    testWidgets(
        'Selecting a filter updates event deck and safely reconciles index',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Filter bar is present
      expect(find.byType(EventFilterBar), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // Tap "Upcoming" filter chip
      await tester.tap(find.text('Upcoming'));
      await tester.pumpAndSettle();

      // Shows only upcoming event
      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);
      expect(find.text('Global Web3 Hackathon 2026'), findsNothing);
      expect(find.text('01'), findsOneWidget);
      expect(find.text(' / 01'), findsOneWidget);
    });

    testWidgets(
        'Renders EmptyStateWidget when no events match filter with Reset Filters action',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Tap "Archived" filter chip (0 archived events in mock)
      await tester.tap(find.text('Archived'));
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No Archived Events'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);

      // Tap Reset Filters
      await tester.tap(find.text('Reset Filters'));
      await tester.pumpAndSettle();

      // Restores All events deck
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
    });

    testWidgets(
        'Live attendance check-in button is displayed when attendance is open',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Top card has attendance open
      expect(find.text('ATTENDANCE OPEN'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets(
        'Renders deterministic fallback banner when banner is empty or missing',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Navigate to 3rd event which has empty banner
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      expect(find.text('DeFi Architecture Workshop'), findsOneWidget);
      // Fallback shows event type watermark and icon
      expect(find.byIcon(Icons.terminal_rounded), findsWidgets);
    });

    testWidgets('Supports Dark and Light themes cleanly', (tester) async {
      final repo = MockEventRepository();

      // Dark Mode
      await tester.pumpWidget(createEventsScreenHarness(
          repository: repo, themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);

      // Light Mode
      await tester.pumpWidget(createEventsScreenHarness(
          repository: repo, themeMode: ThemeMode.light));
      await tester.pumpAndSettle();
      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
    });

    testWidgets(
        'Handles narrow screen dimensions responsively without overflow',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(
        repository: repo,
        screenSize: const Size(320, 568), // iPhone SE / small Android phone
      ));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Respects reduced motion preferences', (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(
        repository: repo,
        disableAnimations: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Global Web3 Hackathon 2026'), findsOneWidget);
      // Next button still transitions cleanly
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);
    });

    testWidgets('Search query filters events by title in real-time',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      // Open search bar
      await tester.tap(find.byTooltip('Search Events'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'DeFi');
      await tester.pumpAndSettle();

      // Only DeFi event is shown in deck
      expect(find.text('DeFi Architecture Workshop'), findsOneWidget);
      expect(find.text('Global Web3 Hackathon 2026'), findsNothing);
      expect(find.text('01'), findsOneWidget);
      expect(find.text(' / 01'), findsOneWidget);
    });

    testWidgets(
        'Rapid consecutive navigation clicks do not corrupt index or throw exceptions',
        (tester) async {
      final repo = MockEventRepository();
      await tester.pumpWidget(createEventsScreenHarness(repository: repo));
      await tester.pumpAndSettle();

      final nextBtn = find.byIcon(Icons.chevron_right_rounded);

      // Rapidly tap next button while animation is in flight
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 30));
      // Second tap while animating should be ignored safely without throwing
      await tester.tap(nextBtn);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();

      // Advanced cleanly to event 2 without crash or overlapping corrupt state
      expect(find.text('Smart Contract Security Seminar'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Subsequent tap after completion advances to event 3
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('DeFi Architecture Workshop'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets(
        'EventSwipeDeck invokes card action callbacks reliably without swiping',
        (tester) async {
      EventEntity? tappedEvent;
      EventEntity? scanEvent;
      EventEntity? editEvent;
      final testEvents = MockEventRepository().mockEvents;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EventSwipeDeck(
                events: testEvents,
                currentIndex: 0,
                cardWidth: 340,
                cardHeight: 520,
                onIndexChanged: (_) {},
                onCardTap: (e) => tappedEvent = e,
                onScanAttendance: (e) => scanEvent = e,
                onEdit: (e) => editEvent = e,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Scan' button
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      expect(scanEvent?.id, 'event-ongoing-1');

      // Tap 'Explore Event'
      await tester.tap(find.text('Explore Event'));
      await tester.pumpAndSettle();
      expect(tappedEvent?.id, 'event-ongoing-1');

      // Tap 'Edit' icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      expect(editEvent?.id, 'event-ongoing-1');
    });
  });
}
