import 'dart:math';

class HeatmapEventEntity {
  final String id;
  final String title;
  final String? type;
  final String? status;
  final String? venue;
  final int? capacity;
  final int? count;
  final bool isAttendanceOpen;
  final DateTime? startDate;
  final DateTime? endDate;

  const HeatmapEventEntity({
    required this.id,
    required this.title,
    this.type,
    this.status,
    this.venue,
    this.capacity,
    this.count,
    this.isAttendanceOpen = false,
    this.startDate,
    this.endDate,
  });
}

class HeatmapDayEntity {
  final String date;
  final int count;
  final List<HeatmapEventEntity> events;

  const HeatmapDayEntity({
    required this.date,
    required this.count,
    this.events = const [],
  });

  DateTime get dateTime => DateTime.parse(date);
}

class HeatmapBusiestDayEntity {
  final String date;
  final int count;

  const HeatmapBusiestDayEntity({
    required this.date,
    required this.count,
  });

  DateTime get dateTime => DateTime.parse(date);
}

class HeatmapStatsEntity {
  final int totalCount;
  final int activeDays;
  final HeatmapBusiestDayEntity? busiestDay;
  final String busiestPeriod;
  final int? completedCount;
  final int? upcomingCount;

  const HeatmapStatsEntity({
    required this.totalCount,
    required this.activeDays,
    this.busiestDay,
    this.busiestPeriod = 'None',
    this.completedCount,
    this.upcomingCount,
  });
}

class ActivityHeatmapEntity {
  final int year;
  final String metric;
  final String timezone;
  final HeatmapStatsEntity stats;
  final Map<String, HeatmapDayEntity> daysMap;

  const ActivityHeatmapEntity({
    required this.year,
    required this.metric,
    required this.timezone,
    required this.stats,
    required this.daysMap,
  });

  HeatmapDayEntity getDay(String dateStr) {
    return daysMap[dateStr] ?? HeatmapDayEntity(date: dateStr, count: 0, events: const []);
  }

  /// Calculates dynamic intensity thresholds [t1, t2, t3, t4] based on the distribution
  /// of positive counts across the year.
  /// Level 0: count == 0
  /// Level 1: 1 <= count <= t1
  /// Level 2: t1 < count <= t2
  /// Level 3: t2 < count <= t3
  /// Level 4: count > t3 (or count >= t4)
  List<int> calculateThresholds() {
    final positiveCounts = daysMap.values
        .map((d) => d.count)
        .where((c) => c > 0)
        .toList()
      ..sort();

    if (positiveCounts.isEmpty) {
      return [1, 2, 3, 4];
    }

    final maxVal = positiveCounts.last;
    if (maxVal <= 4) {
      return [1, 2, 3, 4];
    }

    // Hybrid quantile thresholds based on non-zero count distribution
    int percentile(double p) {
      final index = ((positiveCounts.length - 1) * p).round();
      return positiveCounts[index];
    }

    final p25 = percentile(0.25);
    final p50 = percentile(0.50);
    final p75 = percentile(0.75);

    final t1 = max(1, p25);
    final t2 = max(t1 + 1, p50);
    final t3 = max(t2 + 1, p75);
    final t4 = max(t3 + 1, maxVal);

    return [t1, t2, t3, t4];
  }

  /// Resolves the intensity level (0 to 4) for a specific daily count.
  int getIntensityLevel(int count, [List<int>? thresholds]) {
    if (count <= 0) return 0;
    final th = thresholds ?? calculateThresholds();
    if (count <= th[0]) return 1;
    if (count <= th[1]) return 2;
    if (count <= th[2]) return 3;
    return 4;
  }
}
