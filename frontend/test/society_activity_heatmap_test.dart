import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/core/errors/failures.dart';
import 'package:brl_nexus/core/theme/app_colors.dart';
import 'package:brl_nexus/features/analytics/domain/entities/activity_heatmap_entity.dart';
import 'package:brl_nexus/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:brl_nexus/features/analytics/presentation/utils/heatmap_calendar_utils.dart';
import 'package:brl_nexus/features/analytics/presentation/widgets/heatmap_calendar_grid.dart';
import 'package:brl_nexus/features/analytics/presentation/widgets/heatmap_cell.dart';
import 'package:brl_nexus/features/analytics/presentation/widgets/heatmap_day_details_sheet.dart';
import 'package:brl_nexus/features/analytics/presentation/widgets/heatmap_legend.dart';
import 'package:brl_nexus/features/analytics/presentation/widgets/society_activity_heatmap_card.dart';
import 'package:brl_nexus/features/analytics/providers/analytics_provider.dart';

class MockAnalyticsRepository implements AnalyticsRepository {
  ActivityHeatmapEntity? mockHeatmap;
  Failure? failure;
  int callCount = 0;
  int? lastRequestedYear;
  String? lastRequestedMetric;

  MockAnalyticsRepository({this.mockHeatmap, this.failure});

  @override
  Future<Either<Failure, ActivityHeatmapEntity>> getActivityHeatmap({
    required int year,
    required String metric,
    String? timezone,
  }) async {
    callCount++;
    lastRequestedYear = year;
    lastRequestedMetric = metric;

    if (failure != null) {
      return Left(failure!);
    }

    if (mockHeatmap != null) {
      return Right(mockHeatmap!);
    }

    // Default sample test data
    final daysMap = <String, HeatmapDayEntity>{
      '$year-03-10': HeatmapDayEntity(
        date: '$year-03-10',
        count: 2,
        events: const [
          HeatmapEventEntity(
            id: 'ev-1',
            title: 'Solidity Deep Dive',
            type: 'workshop',
            status: 'completed',
            venue: 'Audi 1',
          ),
          HeatmapEventEntity(
            id: 'ev-2',
            title: 'Web3 Hackathon',
            type: 'hackathon',
            status: 'ongoing',
            venue: 'Lab 2',
          ),
        ],
      ),
      '$year-03-11': HeatmapDayEntity(
        date: '$year-03-11',
        count: 1,
        events: const [
          HeatmapEventEntity(
            id: 'ev-2',
            title: 'Web3 Hackathon',
            type: 'hackathon',
            status: 'ongoing',
          ),
        ],
      ),
      '$year-04-05': HeatmapDayEntity(
        date: '$year-04-05',
        count: 1,
        events: const [
          HeatmapEventEntity(
            id: 'ev-3',
            title: 'Core Team Meeting',
            type: 'meeting',
            status: 'upcoming',
          ),
        ],
      ),
    };

    return Right(ActivityHeatmapEntity(
      year: year,
      metric: metric,
      timezone: 'Asia/Kolkata',
      stats: HeatmapStatsEntity(
        totalCount: metric == 'events' ? 3 : 150,
        activeDays: 3,
        busiestDay: HeatmapBusiestDayEntity(date: '$year-03-10', count: metric == 'events' ? 2 : 80),
        busiestPeriod: 'March',
        completedCount: 1,
        upcomingCount: 2,
      ),
      daysMap: daysMap,
    ));
  }
}

void main() {
  group('HeatmapCalendarUtils - Calendar Grid Calculations', () {
    test('Calculates total days correctly for normal (365) and leap years (366)', () {
      final grid2025 = HeatmapCalendarUtils.generateGrid(2025);
      expect(grid2025.isLeapYear, isFalse);
      expect(grid2025.totalDays, 365);

      final grid2024 = HeatmapCalendarUtils.generateGrid(2024);
      expect(grid2024.isLeapYear, isTrue);
      expect(grid2024.totalDays, 366);

      final grid2026 = HeatmapCalendarUtils.generateGrid(2026);
      expect(grid2026.isLeapYear, isFalse);
      expect(grid2026.totalDays, 365);
    });

    test('Aligns January 1 correctly on its weekday row with leading nulls', () {
      // 2026-01-01 is a Thursday (Thursday is index 4 if Sunday=0)
      final grid2026 = HeatmapCalendarUtils.generateGrid(2026);
      final firstCol = grid2026.columns[0];

      // Sunday(0), Monday(1), Tuesday(2), Wednesday(3) must be null
      expect(firstCol[0], isNull);
      expect(firstCol[1], isNull);
      expect(firstCol[2], isNull);
      expect(firstCol[3], isNull);

      // Thursday(4) must be Jan 1, 2026
      expect(firstCol[4], isNotNull);
      expect(firstCol[4]!.dateKey, '2026-01-01');
      expect(firstCol[4]!.weekdayIndex, 4);

      // Friday(5) and Saturday(6)
      expect(firstCol[5]!.dateKey, '2026-01-02');
      expect(firstCol[6]!.dateKey, '2026-01-03');
    });

    test('Aligns December 31 correctly in the final column with trailing nulls if applicable', () {
      final grid2026 = HeatmapCalendarUtils.generateGrid(2026);
      final lastCol = grid2026.columns.last;

      // 2026-12-31 is a Thursday (row 4)
      final dec31 = lastCol.firstWhere((d) => d?.dateKey == '2026-12-31');
      expect(dec31, isNotNull);
      expect(dec31!.weekdayIndex, 4);

      // Friday(5) and Saturday(6) in last week should be null
      expect(lastCol[5], isNull);
      expect(lastCol[6], isNull);
    });

    test('Generates month headers for all 12 months with strictly increasing column indices', () {
      final grid2026 = HeatmapCalendarUtils.generateGrid(2026);
      expect(grid2026.monthHeaders.length, 12);
      expect(grid2026.monthHeaders[0].label, 'Jan');
      expect(grid2026.monthHeaders[0].columnIndex, 0);

      for (int i = 1; i < grid2026.monthHeaders.length; i++) {
        expect(grid2026.monthHeaders[i].columnIndex, greaterThanOrEqualTo(grid2026.monthHeaders[i - 1].columnIndex));
      }
    });
  });

  group('ActivityHeatmapEntity - Intensity Normalization', () {
    test('Empty counts map directly to Level 0', () {
      const entity = ActivityHeatmapEntity(
        year: 2026,
        metric: 'events',
        timezone: 'Asia/Kolkata',
        stats: HeatmapStatsEntity(totalCount: 0, activeDays: 0),
        daysMap: {},
      );

      expect(entity.getIntensityLevel(0), 0);
    });

    test('Small distribution (maxCount <= 4) maps 1, 2, 3, 4 directly to distinct levels', () {
      final daysMap = {
        '2026-01-01': const HeatmapDayEntity(date: '2026-01-01', count: 1),
        '2026-01-02': const HeatmapDayEntity(date: '2026-01-02', count: 2),
        '2026-01-03': const HeatmapDayEntity(date: '2026-01-03', count: 3),
        '2026-01-04': const HeatmapDayEntity(date: '2026-01-04', count: 4),
      };

      final entity = ActivityHeatmapEntity(
        year: 2026,
        metric: 'events',
        timezone: 'Asia/Kolkata',
        stats: const HeatmapStatsEntity(totalCount: 10, activeDays: 4),
        daysMap: daysMap,
      );

      expect(entity.getIntensityLevel(0), 0);
      expect(entity.getIntensityLevel(1), 1);
      expect(entity.getIntensityLevel(2), 2);
      expect(entity.getIntensityLevel(3), 3);
      expect(entity.getIntensityLevel(4), 4);
      expect(entity.getIntensityLevel(5), 4);
    });

    test('Large attendance count distribution uses quantile thresholds without distortion', () {
      final daysMap = <String, HeatmapDayEntity>{};
      final counts = [10, 15, 20, 25, 40, 50, 75, 90, 120, 200];
      for (int i = 0; i < counts.length; i++) {
        final dStr = '2026-02-${(i + 1).toString().padLeft(2, '0')}';
        daysMap[dStr] = HeatmapDayEntity(date: dStr, count: counts[i]);
      }

      final entity = ActivityHeatmapEntity(
        year: 2026,
        metric: 'attendance',
        timezone: 'Asia/Kolkata',
        stats: const HeatmapStatsEntity(totalCount: 645, activeDays: 10),
        daysMap: daysMap,
      );

      final th = entity.calculateThresholds();
      expect(th.length, 4);
      expect(th[0], lessThan(th[1]));
      expect(th[1], lessThan(th[2]));
      expect(th[2], lessThan(th[3]));

      // 0 is always level 0
      expect(entity.getIntensityLevel(0), 0);
      // Smallest count is level 1
      expect(entity.getIntensityLevel(10), 1);
      // Largest count is level 4
      expect(entity.getIntensityLevel(200), 4);
    });
  });

  group('SocietyActivityHeatmapCard Widget Tests', () {
    testWidgets('Renders header, subtitle, year selector, and metric pills', (tester) async {
      final mockRepo = MockAnalyticsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SocietyActivityHeatmapCard(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Heading and subtitle
      expect(find.text('Society Activity'), findsOneWidget);
      expect(find.text('Your year in events and attendance'), findsOneWidget);

      // Year selector
      expect(find.text('2026'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Metric pills
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);

      // Summary statistics chips
      expect(find.text('Total Events'), findsOneWidget);
      expect(find.text('Active Days'), findsOneWidget);
      expect(find.text('Peak Day'), findsOneWidget);

      // Calendar components
      expect(find.byType(HeatmapCalendarGrid), findsOneWidget);
      expect(find.byType(HeatmapLegend), findsOneWidget);
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Metric selector switches between Events and Attendance', (tester) async {
      final mockRepo = MockAnalyticsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SocietyActivityHeatmapCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Total Events'), findsOneWidget);

      // Tap "Attendance" pill
      await tester.tap(find.text('Attendance'));
      await tester.pumpAndSettle();

      expect(find.text('Total Check-ins'), findsOneWidget);
      expect(mockRepo.lastRequestedMetric, 'attendance');
    });

    testWidgets('Year selector decrements and loads previous year data', (tester) async {
      final mockRepo = MockAnalyticsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SocietyActivityHeatmapCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);

      // Tap left chevron to go to 2025
      await tester.tap(find.byIcon(Icons.chevron_left_rounded));
      await tester.pumpAndSettle();

      expect(find.text('2025'), findsOneWidget);
      expect(mockRepo.lastRequestedYear, 2025);
    });

    testWidgets('Tapping a cell displays the HeatmapDayDetailsSheet with event details', (tester) async {
      final mockRepo = MockAnalyticsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SocietyActivityHeatmapCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find visible cells in grid
      final cells = find.byWidgetPredicate(
        (widget) => widget is HeatmapCell && widget.day != null && widget.onTap != null,
      );
      expect(cells, findsWidgets);

      // Tap a visible cell at current scroll viewport
      final elements = cells.evaluate().toList();
      final targetIndex = (elements.length * 0.75).round().clamp(0, elements.length - 1);
      await tester.tap(cells.at(targetIndex));
      await tester.pumpAndSettle();

      // Bottom sheet should open with formatted day details
      expect(find.byType(HeatmapDayDetailsSheet), findsOneWidget);
      expect(find.textContaining('Society Event Activity'), findsOneWidget);
    });

    testWidgets('Renders legitimate empty state when year has no activity', (tester) async {
      final mockRepo = MockAnalyticsRepository(
        mockHeatmap: const ActivityHeatmapEntity(
          year: 2023,
          metric: 'events',
          timezone: 'Asia/Kolkata',
          stats: HeatmapStatsEntity(totalCount: 0, activeDays: 0, busiestPeriod: 'None'),
          daysMap: {},
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SocietyActivityHeatmapCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Shows zero-activity informational message
      expect(find.text('No recorded activity for this year yet.'), findsOneWidget);
      // Calendar grid is still rendered with empty cells
      expect(find.byType(HeatmapCalendarGrid), findsOneWidget);
    });

    testWidgets('Renders error state with localized retry button on failure', (tester) async {
      final mockRepo = MockAnalyticsRepository(
        failure: const ServerFailure('Database connection timeout'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: SocietyActivityHeatmapCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unable to load activity heatmap'), findsOneWidget);
      expect(find.textContaining('Database connection timeout'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Renders cleanly in both Light Mode and Dark Mode', (tester) async {
      final mockRepo = MockAnalyticsRepository();

      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              analyticsRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                scaffoldBackgroundColor: brightness == Brightness.dark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: SocietyActivityHeatmapCard(),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Society Activity'), findsOneWidget);
      }
    });
  });
}
