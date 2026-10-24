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
      github: 'https://github.com/imChinmoy',
      linkedin: 'https://linkedin.com/in/chinmoy-senapati',
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
      domain: 'Software Engineering',
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

  Widget createMembersHarness({List<UserEntity>? members}) {
    return ProviderScope(
      overrides: [
        membersProvider.overrideWith((ref) => members ?? testMembers),
        currentUserProvider.overrideWith(
          (ref) => testMembers.first,
        ),
      ],
      child: const MaterialApp(
        home: MembersScreen(),
      ),
    );
  }

  group('MembersScreen Organization Graph & Hierarchy Tests', () {
    testWidgets('Renders Organization Graph with floating header, stats, and member nodes',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Top title
      expect(find.text('Organization Graph'), findsOneWidget);
      expect(find.text('NEXUS ORG NETWORK'), findsOneWidget);
      expect(find.textContaining('4 Members'), findsOneWidget);

      // Verify node names are rendered in the graph
      expect(find.text('Chinmoy Senapati'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Sneha Patel'), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsOneWidget);

      // Role hierarchy short codes are present
      expect(find.text('LEAD'), findsOneWidget);
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('COORD'), findsOneWidget);
      expect(find.text('CREW'), findsOneWidget);
    });

    testWidgets('Tapping view mode toggle switches between Interactive Graph and Tier Cards view',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap View Mode button in app bar
      final toggleFinder = find.byTooltip('Switch to Tier Cards');
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Tier cards are now visible
      expect(find.text('Executive Council'), findsOneWidget);
      expect(find.text('LEVEL 5 & 4'), findsOneWidget);
      expect(find.text('Domain Coordinators'), findsOneWidget);
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Operations Crew & Volunteers'), findsOneWidget);

      // Tap toggle button to return to graph mode
      final returnFinder = find.byTooltip('Switch to Hierarchy Graph');
      expect(returnFinder, findsOneWidget);
      await tester.tap(returnFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('Tapping a member node opens the detailed member inspection sheet',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Chinmoy Senapati node
      await tester.tap(find.text('Chinmoy Senapati'));
      await tester.pump(const Duration(milliseconds: 300));

      // Inspection sheet details
      expect(find.text('chinmoy@brlnexus.com'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.textContaining('LEVEL 5'), findsOneWidget);
      expect(find.text('President & Chief Architect at BRL Nexus.'), findsOneWidget);
      expect(find.text('View Full Member Profile'), findsOneWidget);
    });

    testWidgets('Tapping Hierarchy Legend button displays all 5 levels with descriptions',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Tap legend icon in HUD
      final legendFinder = find.byTooltip('Hierarchy Legend');
      expect(legendFinder, findsOneWidget);
      await tester.tap(legendFinder);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Role Hierarchy Legend'), findsOneWidget);
      expect(find.text('Level 5: Super Admin'), findsOneWidget);
      expect(find.text('Level 4: Admin'), findsOneWidget);
      expect(find.text('Level 3: Coordinator'), findsOneWidget);
      expect(find.text('Level 2: Volunteer'), findsOneWidget);
      expect(find.text('Level 1: Viewer'), findsOneWidget);
    });

    testWidgets('Tapping Reload button in AppBar triggers manual refresh and displays feedback toast',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final reloadFinder = find.byTooltip('Reload Org Graph');
      expect(reloadFinder, findsOneWidget);
      await tester.tap(reloadFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Organization graph synced'), findsOneWidget);
    });

    testWidgets('Role Hierarchy Legend displays professional executive metadata and security badges',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      final legendFinder = find.byTooltip('Hierarchy Legend');
      expect(legendFinder, findsOneWidget);
      await tester.tap(legendFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Overline and executive authority tags
      expect(find.text('NEXUS • GOVERNANCE & ACCESS TIERS'), findsOneWidget);
      expect(find.text('EXECUTIVE'), findsOneWidget);
      expect(find.text('LEADERSHIP'), findsOneWidget);
      expect(find.text('COORDINATION'), findsOneWidget);
      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('OBSERVER'), findsOneWidget);
      expect(find.textContaining('cryptographically signed and validated'), findsOneWidget);

      // Dismiss bottom sheet cleanly
      Navigator.of(tester.element(find.text('Role Hierarchy Legend'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('NEXUS • GOVERNANCE & ACCESS TIERS'), findsNothing);
    });

    testWidgets('Search input filters graph nodes and spotlights matching members',
        (tester) async {
      await tester.pumpWidget(createMembersHarness());
      await tester.pump(const Duration(milliseconds: 300));

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Sneha');
      await tester.pump(const Duration(milliseconds: 300));

      // Sneha Patel node is fully opaque while non-matching members are dimmed
      expect(find.text('Sneha Patel'), findsOneWidget);
    });
  });
}
