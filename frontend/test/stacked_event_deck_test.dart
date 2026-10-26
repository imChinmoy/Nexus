import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/features/dashboard/presentation/widgets/stacked_event_deck.dart';
import 'package:brl_nexus/features/events/domain/entities/event_entity.dart';

void main() {
  final testEvents = [
    EventEntity(
      id: 'event-1',
      title: 'Flagship Tech Summit',
      description: 'The premier annual engineering conference',
      venue: 'Main Auditorium',
      banner: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
      startDate: DateTime.now().subtract(const Duration(hours: 1)),
      endDate: DateTime.now().add(const Duration(hours: 3)),
      type: 'summit',
      capacity: 300,
      status: 'ongoing',
      isAttendanceOpen: true,
    ),
    EventEntity(
      id: 'event-2',
      title: 'Web3 & AI Workshop',
      description: 'Hands-on smart contract and LLM architecture lab',
      venue: 'Lab Complex 3',
      banner: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4',
      startDate: DateTime.now().add(const Duration(days: 3)),
      endDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
      type: 'workshop',
      capacity: 80,
      status: 'upcoming',
      isAttendanceOpen: false,
    ),
    EventEntity(
      id: 'event-3',
      title: 'Global Hackathon 2026',
      description: '48-hour continuous building challenge',
      venue: 'Innovation Hub',
      banner: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d',
      startDate: DateTime.now().add(const Duration(days: 14)),
      endDate: DateTime.now().add(const Duration(days: 16)),
      type: 'hackathon',
      capacity: 500,
      status: 'upcoming',
      isAttendanceOpen: false,
    ),
  ];

  Widget buildDeckHarness({
    required List<EventEntity> events,
    int activeIndex = 0,
    bool isDark = true,
    bool isAdmin = false,
    ValueChanged<int>? onIndexChanged,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: StackedEventDeck(
              events: events,
              activeIndex: activeIndex,
              isDark: isDark,
              isAdmin: isAdmin,
              onIndexChanged: onIndexChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  group('StackedEventDeck — True Layered Deck Carousel Tests', () {
    testWidgets('Renders 3-card layered deck in resting state with foreground and rotated background cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
      ));
      await tester.pumpAndSettle();

      // Foreground active card (event-1)
      expect(find.text('Flagship Tech Summit'), findsOneWidget);
      expect(find.text('LIVE CHECK-IN OPEN'), findsWidgets);
      expect(find.text('Main Auditorium'), findsWidgets);
      expect(find.text('View Event'), findsOneWidget);
      expect(find.text('Scan QR Pass'), findsOneWidget);

      // Left background card (event-3) peeking behind
      expect(find.text('GLOBAL HACKATHON 2026'), findsOneWidget);

      // Right background card (event-2) peeking behind
      expect(find.text('WEB3 & AI WORKSHOP'), findsOneWidget);

      // Position Indicator: 3 dots rendered
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('Background cards apply opposite rotations in resting state',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
      ));
      await tester.pumpAndSettle();

      final transforms = tester.widgetList<Transform>(find.byType(Transform)).toList();
      // Verify that transforms exist for left background, right background, and active card
      expect(transforms.length, greaterThanOrEqualTo(3));

      // Left card has negative rotation (~ -6° = -0.105 rad)
      // Right card has positive rotation (~ +6° = +0.105 rad)
      // Foreground card has 0 rotation in resting state
      final matrixLeft = transforms[0].transform;
      final matrixRight = transforms[1].transform;
      final matrixActive = transforms[2].transform;

      // Extract rotation entries from 4x4 matrix
      expect(matrixLeft.storage[1], lessThan(0)); // sin(theta) < 0 => negative rotation
      expect(matrixRight.storage[1], greaterThan(0)); // sin(theta) > 0 => positive rotation
      expect(matrixActive.storage[1], closeTo(0.0, 0.001)); // straight at rest
    });

    testWidgets('Cover images render crisply without blur filter and foreground text remains sharp',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
      ));
      await tester.pumpAndSettle();

      // ImageFiltered blur should NOT be applied to card artwork
      expect(find.byType(ImageFiltered), findsNothing);

      // Foreground text remains sharp and visible
      final titleFinder = find.text('Flagship Tech Summit');
      expect(titleFinder, findsOneWidget);

      final buttonFinder = find.text('View Event');
      expect(buttonFinder, findsOneWidget);
    });

    testWidgets('Tapping left background card switches to previous event',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? changedIndex;
      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
        onIndexChanged: (idx) => changedIndex = idx,
      ));
      await tester.pumpAndSettle();

      // Tap left peeking card wing (event-3, index 2)
      await tester.tap(find.byKey(const ValueKey('deck_left_wing_tap')));
      await tester.pumpAndSettle();

      expect(changedIndex, 2);
    });

    testWidgets('Tapping right background card switches to next event',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? changedIndex;
      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
        onIndexChanged: (idx) => changedIndex = idx,
      ));
      await tester.pumpAndSettle();

      // Tap right peeking card wing (event-2, index 1)
      await tester.tap(find.byKey(const ValueKey('deck_right_wing_tap')));
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
    });

    testWidgets('Horizontal drag gesture smoothly moves cards and triggers swipe navigation on release',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? changedIndex;
      await tester.pumpWidget(buildDeckHarness(
        events: testEvents,
        activeIndex: 0,
        onIndexChanged: (idx) => changedIndex = idx,
      ));
      await tester.pumpAndSettle();

      // Drag left with velocity to advance to next event
      await tester.fling(find.text('Flagship Tech Summit'), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
    });

    testWidgets('Single event renders active card alone without background peek cards',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildDeckHarness(
        events: [testEvents[0]],
        activeIndex: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Flagship Tech Summit'), findsOneWidget);
      // No background card titles
      expect(find.text('GLOBAL HACKATHON 2026'), findsNothing);
      expect(find.text('WEB3 & AI WORKSHOP'), findsNothing);
    });
  });
}
