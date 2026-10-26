import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/features/auth/domain/entities/user_entity.dart';
import 'package:brl_nexus/features/auth/providers/auth_provider.dart';
import 'package:brl_nexus/features/members/presentation/screens/members_screen.dart';
import 'package:brl_nexus/features/members/providers/members_provider.dart';

void main() {
  final testMembers = [
    UserEntity(
      id: 'mem-1',
      name: 'Chinmoy Senapati',
      email: 'chinmoy@brlnexus.com',
      role: UserRole.superAdmin,
      year: '4th Year',
      domain: 'Technical & Architecture',
      phone: '+91 98765 43210',
      bio: 'President & Chief Architect at BRL Nexus.',
      isActive: true,
      createdAt: DateTime(2025, 8, 1),
      updatedAt: DateTime(2026, 1, 15),
    ),
    UserEntity(
      id: 'mem-2',
      name: 'Aarav Sharma',
      email: 'aarav.tech@brlnexus.com',
      role: UserRole.admin,
      year: '3rd Year',
      domain: 'Web & Mobile Dev',
      phone: '+91 98765 11223',
      bio: 'Vice Lead & Systems Engineer.',
      isActive: true,
      createdAt: DateTime(2025, 9, 1),
      updatedAt: DateTime(2026, 2, 10),
    ),
    UserEntity(
      id: 'mem-3',
      name: 'Sneha Patel',
      email: 'sneha.design@brlnexus.com',
      role: UserRole.coordinator,
      year: '3rd Year',
      domain: 'UI/UX & Brand Design',
      phone: '+91 98222 33445',
      bio: 'Design Systems Lead.',
      isActive: true,
      createdAt: DateTime(2025, 10, 5),
      updatedAt: DateTime(2026, 3, 5),
    ),
    UserEntity(
      id: 'mem-4',
      name: 'Vikram Malhotra',
      email: 'vikram.m@brlnexus.com',
      role: UserRole.volunteer,
      year: '2nd Year',
      domain: 'Web & Mobile Dev',
      bio: 'Frontend associate.',
      isActive: true,
      createdAt: DateTime(2025, 12, 1),
      updatedAt: DateTime(2026, 3, 20),
    ),
  ];

  Widget createMembersHarness({
    List<UserEntity>? members,
    ThemeMode themeMode = ThemeMode.dark,
  }) {
    return ProviderScope(
      overrides: [
        membersProvider.overrideWith((ref) => members ?? testMembers),
        currentUserProvider.overrideWith((ref) => testMembers.first),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: const MembersScreen(),
      ),
    );
  }

  group('DraggableOrgNetworkFab — Collapsed & Dragging Mechanics', () {
    testWidgets('Renders collapsed FAB with live member count and network hub icon', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));
      expect(fabFinder, findsOneWidget);
      expect(find.textContaining('4 Members'), findsOneWidget);
      expect(find.text('ORG NETWORK'), findsOneWidget);
      expect(find.byIcon(Icons.hub_rounded), findsWidgets);

      // Expanded title and search field are not initially visible
      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('Horizontal and vertical dragging repositions the FAB smoothly', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));
      final initialOffset = tester.getTopLeft(fabFinder);

      // Drag left and down
      await tester.drag(fabFinder, const Offset(-120, 80));
      await tester.pump();

      final newOffset = tester.getTopLeft(fabFinder);
      expect(newOffset.dx, isNot(equals(initialOffset.dx)));
      expect(newOffset.dy, isNot(equals(initialOffset.dy)));
    });

    testWidgets('Releasing FAB snaps smoothly toward nearest safe edge', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));

      // Drag across towards the left side (offset -400)
      await tester.drag(fabFinder, const Offset(-400, 50));
      await tester.pump();
      // Allow snap animation to settle
      await tester.pump(const Duration(milliseconds: 350));

      final snappedOffset = tester.getTopLeft(fabFinder);
      // Left edge safe margin is 14.0
      expect(snappedOffset.dx, closeTo(14.0, 4.0));
      // Card remains collapsed
      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
    });

    testWidgets('Dragging does not open the panel accidentally', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));

      // Deliberate drag motion > 7px threshold
      await tester.drag(fabFinder, const Offset(-80, 40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Panel must stay collapsed
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const Key('close_org_network_panel')), findsNothing);
    });

    testWidgets('FAB cannot be dragged underneath bottom navigation or outside safe bounds', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));

      // Attempt to drag way past the bottom and right bounds
      await tester.drag(fabFinder, const Offset(1000, 2000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final clampedOffset = tester.getTopLeft(fabFinder);
      final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;

      // Position should be safely clamped well above the bottom navigation margin
      expect(clampedOffset.dy, lessThan(screenSize.height - 80));
      expect(clampedOffset.dx, lessThan(screenSize.width));
      expect(clampedOffset.dx, greaterThanOrEqualTo(10.0));
    });

    testWidgets('Screen dimension change reconciles FAB position safely within bounds', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Resize window to landscape
      tester.view.physicalSize = const Size(1400, 700);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));
      final pos = tester.getTopLeft(fabFinder);
      expect(pos.dx, lessThan(1400));
      expect(pos.dy, lessThan(700));
    });
  });

  group('DraggableOrgNetworkFab — Morphing Expansion & Control Deck', () {
    testWidgets('Normal tap smoothly morphs FAB into expanded network controls', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final fabFinder = find.byKey(const Key('draggable_org_fab'));
      await tester.tap(fabFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Expanded panel content is now revealed
      expect(find.text('NEXUS ORG NETWORK'), findsOneWidget);
      expect(find.text('Interactive Society Hierarchy Graph'), findsOneWidget);
      expect(find.textContaining('4 Members'), findsWidgets);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('close_org_network_panel')), findsOneWidget);
      expect(find.byKey(const Key('org_fab_scrim')), findsOneWidget);
    });

    testWidgets('Tapping integrated close button reverses animation back to FAB', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Expand
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Interactive Society Hierarchy Graph'), findsOneWidget);

      // Close
      final closeButton = find.byKey(const Key('close_org_network_panel'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Scrim is dismissed and panel is collapsed back to FAB
      expect(find.byKey(const Key('org_fab_scrim')), findsNothing);
      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
      expect(find.byKey(const Key('draggable_org_fab')), findsOneWidget);
    });

    testWidgets('Tapping outside scrim dismisses expanded panel', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Expand
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('org_fab_scrim')), findsOneWidget);

      // Tap on scrim at the bottom center of the screen
      await tester.tapAt(const Offset(400, 500));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const Key('org_fab_scrim')), findsNothing);
      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
    });

    testWidgets('System back closes expanded panel before leaving screen', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Expand
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('NEXUS ORG NETWORK'), findsOneWidget);

      // Trigger system back pop
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Organization Graph screen remains active, but panel is closed
      expect(find.text('Organization Graph'), findsOneWidget);
      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
    });

    testWidgets('Search query updates graph and clear search button works', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Expand
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Aarav');
      await tester.pump(const Duration(milliseconds: 200));

      // Matching member node is rendered and clear button appears
      expect(find.text('Aarav Sharma'), findsOneWidget);
      final clearButton = find.byKey(const Key('clear_search_button'));
      expect(clearButton, findsOneWidget);

      // Tap clear search button
      await tester.tap(clearButton);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const Key('clear_search_button')), findsNothing);
    });

    testWidgets('Domain filter selection updates active domain chips', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Expand
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Tap domain chip 'Technical & Architecture'
      final domainChip = find.text('Technical & Architecture');
      expect(domainChip, findsOneWidget);
      await tester.tap(domainChip);
      await tester.pump(const Duration(milliseconds: 200));

      // Graph reflects domain filtering
      expect(find.text('Chinmoy Senapati'), findsOneWidget);
    });

    testWidgets('Reduced motion accessibility immediately expands and collapses without animation delay', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membersProvider.overrideWith((ref) => testMembers),
            currentUserProvider.overrideWith((ref) => testMembers.first),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: MembersScreen(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap to expand
      final fabFinder = find.byKey(const Key('draggable_org_fab'));
      await tester.tap(fabFinder);
      await tester.pump(); // immediate update with disableAnimations

      expect(find.text('NEXUS ORG NETWORK'), findsOneWidget);
      expect(find.text('Interactive Society Hierarchy Graph'), findsOneWidget);

      // Tap close
      await tester.tap(find.byKey(const Key('close_org_network_panel')));
      await tester.pump(); // immediate update

      expect(find.text('Interactive Society Hierarchy Graph'), findsNothing);
      expect(find.byKey(const Key('draggable_org_fab')), findsOneWidget);
    });

    testWidgets('Light and Dark themes render correctly with proper styling', (tester) async {
      // Light theme
      await tester.pumpWidget(createMembersHarness(themeMode: ThemeMode.light));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('draggable_org_fab')), findsOneWidget);

      // Expand in light theme
      await tester.tap(find.byKey(const Key('draggable_org_fab')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('NEXUS ORG NETWORK'), findsOneWidget);

      // Collapse back to FAB
      await tester.tap(find.byKey(const Key('close_org_network_panel')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.byKey(const Key('draggable_org_fab')), findsOneWidget);

      // Switch to Dark theme
      await tester.pumpWidget(createMembersHarness(themeMode: ThemeMode.dark));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('draggable_org_fab')), findsOneWidget);
    });
  });

  group('DraggableOrgNetworkFab — Graph Preservation', () {
    testWidgets('Graph canvas panning and node selection work while FAB is collapsed', (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Panning on the interactive viewer canvas
      await tester.drag(find.byType(InteractiveViewer), const Offset(50, -50));
      await tester.pump();

      // Tap member node to open member details bottom sheet
      await tester.tap(find.text('Chinmoy Senapati'));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('chinmoy@brlnexus.com'), findsOneWidget);
      expect(find.text('View Full Member Profile'), findsOneWidget);
    });
  });
}
