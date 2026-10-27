import '../../domain/entities/activity_heatmap_entity.dart';

class HeatmapEventModel extends HeatmapEventEntity {
  const HeatmapEventModel({
    required super.id,
    required super.title,
    super.type,
    super.status,
    super.venue,
    super.capacity,
    super.count,
    super.isAttendanceOpen,
    super.startDate,
    super.endDate,
  });

  factory HeatmapEventModel.fromJson(Map<String, dynamic> json) {
    return HeatmapEventModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Event',
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      venue: json['venue']?.toString(),
      capacity:
          json['capacity'] is num ? (json['capacity'] as num).toInt() : null,
      count: json['count'] is num ? (json['count'] as num).toInt() : null,
      isAttendanceOpen: json['isAttendanceOpen'] == true,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
    );
  }
}

class HeatmapDayModel extends HeatmapDayEntity {
  const HeatmapDayModel({
    required super.date,
    required super.count,
    super.events,
  });

  factory HeatmapDayModel.fromJson(Map<String, dynamic> json) {
    final eventsRaw = json['events'] as List<dynamic>? ?? const [];
    final events = eventsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => HeatmapEventModel.fromJson(e))
        .toList();

    return HeatmapDayModel(
      date: json['date']?.toString() ?? '',
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      events: events,
    );
  }
}

class HeatmapBusiestDayModel extends HeatmapBusiestDayEntity {
  const HeatmapBusiestDayModel({
    required super.date,
    required super.count,
  });

  factory HeatmapBusiestDayModel.fromJson(Map<String, dynamic> json) {
    return HeatmapBusiestDayModel(
      date: json['date']?.toString() ?? '',
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
    );
  }
}

class HeatmapStatsModel extends HeatmapStatsEntity {
  const HeatmapStatsModel({
    required super.totalCount,
    required super.activeDays,
    super.busiestDay,
    super.busiestPeriod,
    super.completedCount,
    super.upcomingCount,
  });

  factory HeatmapStatsModel.fromJson(Map<String, dynamic> json) {
    HeatmapBusiestDayModel? busiestDay;
    if (json['busiestDay'] is Map<String, dynamic>) {
      busiestDay = HeatmapBusiestDayModel.fromJson(
          json['busiestDay'] as Map<String, dynamic>);
    }

    return HeatmapStatsModel(
      totalCount:
          json['totalCount'] is num ? (json['totalCount'] as num).toInt() : 0,
      activeDays:
          json['activeDays'] is num ? (json['activeDays'] as num).toInt() : 0,
      busiestDay: busiestDay,
      busiestPeriod: json['busiestPeriod']?.toString() ?? 'None',
      completedCount: json['completedCount'] is num
          ? (json['completedCount'] as num).toInt()
          : null,
      upcomingCount: json['upcomingCount'] is num
          ? (json['upcomingCount'] as num).toInt()
          : null,
    );
  }
}

class ActivityHeatmapModel extends ActivityHeatmapEntity {
  const ActivityHeatmapModel({
    required super.year,
    required super.metric,
    required super.timezone,
    required super.stats,
    required super.daysMap,
  });

  factory ActivityHeatmapModel.fromJson(Map<String, dynamic> json) {
    final year = json['year'] is num
        ? (json['year'] as num).toInt()
        : DateTime.now().year;
    final metric = json['metric']?.toString() ?? 'events';
    final timezone = json['timezone']?.toString() ?? 'Asia/Kolkata';

    HeatmapStatsModel stats;
    if (json['stats'] is Map<String, dynamic>) {
      stats = HeatmapStatsModel.fromJson(json['stats'] as Map<String, dynamic>);
    } else {
      stats = const HeatmapStatsModel(totalCount: 0, activeDays: 0);
    }

    final daysRaw = json['days'] as List<dynamic>? ?? const [];
    final daysMap = <String, HeatmapDayEntity>{};
    for (final item in daysRaw) {
      if (item is Map<String, dynamic>) {
        final dayModel = HeatmapDayModel.fromJson(item);
        if (dayModel.date.isNotEmpty) {
          daysMap[dayModel.date] = dayModel;
        }
      }
    }

    return ActivityHeatmapModel(
      year: year,
      metric: metric,
      timezone: timezone,
      stats: stats,
      daysMap: daysMap,
    );
  }
}
