class EventEntity {
  final String id;
  final String title;
  final String? description;
  final String? venue;
  final String? banner;
  final bool isAttendanceOpen;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final int capacity;
  final String status;

  const EventEntity({
    required this.id,
    required this.title,
    this.description,
    this.venue,
    this.banner,
    this.isAttendanceOpen = false,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.capacity,
    required this.status,
  });

  static bool isDateOnly(DateTime dt) {
    return dt.hour == 0 &&
        dt.minute == 0 &&
        dt.second == 0 &&
        dt.millisecond == 0 &&
        dt.microsecond == 0;
  }

  static DateTime getStartBoundary(DateTime start) {
    if (isDateOnly(start)) {
      return DateTime(start.year, start.month, start.day, 0, 0, 0, 0);
    }
    return start;
  }

  static DateTime getEndBoundary(DateTime end) {
    if (isDateOnly(end)) {
      return DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    }
    return end;
  }

  /// Calculates the authoritative timeline status for an event.
  /// Controllable with an optional [now] parameter for testing.
  static String calculateEffectiveStatus({
    required DateTime startDate,
    required DateTime endDate,
    required String rawStatus,
    DateTime? now,
  }) {
    final normalized = rawStatus.toLowerCase().trim();
    if (normalized == 'cancelled') return 'cancelled';
    if (normalized == 'archived') return 'archived';

    final currentInstant = now ?? DateTime.now();
    final startBoundary = getStartBoundary(startDate);
    final endBoundary = getEndBoundary(endDate);

    if (currentInstant.isAfter(endBoundary)) {
      return 'completed';
    }
    if (currentInstant.isBefore(startBoundary)) {
      return 'upcoming';
    }
    return 'ongoing';
  }

  bool isPastAt([DateTime? now]) {
    final current = now ?? DateTime.now();
    return current.isAfter(getEndBoundary(endDate));
  }

  bool get isPast => isPastAt();
  bool get isOngoing => effectiveStatus == 'ongoing';
  bool get isUpcoming => effectiveStatus == 'upcoming';

  /// Normalized effective status ensuring timeline consistency
  String get effectiveStatus => calculateEffectiveStatus(
        startDate: startDate,
        endDate: endDate,
        rawStatus: status,
      );

  String effectiveStatusAt(DateTime now) => calculateEffectiveStatus(
        startDate: startDate,
        endDate: endDate,
        rawStatus: status,
        now: now,
      );

  /// Checks if this event matches the requested category filter
  bool matchesFilter(String? filter, [DateTime? now]) {
    if (filter == null || filter.isEmpty || filter.toLowerCase() == 'all') {
      return true;
    }
    final f = filter.toLowerCase().trim();
    final eff = effectiveStatusAt(now ?? DateTime.now()).toLowerCase();
    if (f == 'ended' || f == 'completed') {
      return eff == 'completed' || eff == 'ended';
    }
    return eff == f;
  }

  /// Compares two events chronologically taking into account year, date, time, and end date.
  static int chronologicalComparator(EventEntity a, EventEntity b) {
    final startComp = a.startDate.compareTo(b.startDate);
    if (startComp != 0) return startComp;
    final endComp = a.endDate.compareTo(b.endDate);
    if (endComp != 0) return endComp;
    return a.title.compareTo(b.title);
  }

  /// Returns a new list of events sorted strictly chronologically.
  static List<EventEntity> sortChronologically(List<EventEntity> events) {
    final list = List<EventEntity>.from(events);
    list.sort(chronologicalComparator);
    return list;
  }

  /// Finds the index of the default landing event:
  /// 1. Ongoing event closest to current time (if any).
  /// 2. Upcoming event closest to current date/time (if any).
  /// 3. Fallback: Most recent past event (closest ended event to now).
  static int findDefaultEventIndex(List<EventEntity> events,
      [DateTime? clock]) {
    if (events.isEmpty) return 0;
    final now = clock ?? DateTime.now();

    // 1. Ongoing events: pick the one closest to now (or earliest start)
    int? ongoingIdx;
    Duration? minOngoingDiff;
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      if (e.effectiveStatusAt(now) == 'ongoing') {
        final diff = (now.difference(e.startDate)).abs();
        if (minOngoingDiff == null || diff < minOngoingDiff) {
          minOngoingDiff = diff;
          ongoingIdx = i;
        }
      }
    }
    if (ongoingIdx != null) return ongoingIdx;

    // 2. Upcoming events: pick the upcoming event closest to now (minimal positive diff)
    int? upcomingIdx;
    Duration? minUpcomingDiff;
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      final status = e.effectiveStatusAt(now);
      if (status == 'upcoming' || e.startDate.isAfter(now)) {
        final diff = e.startDate.difference(now);
        if (diff >= Duration.zero &&
            (minUpcomingDiff == null || diff < minUpcomingDiff)) {
          minUpcomingDiff = diff;
          upcomingIdx = i;
        }
      }
    }
    if (upcomingIdx != null) return upcomingIdx;

    // 3. Fallback: Pick the most recent past event (closest ended event)
    int? pastIdx;
    Duration? minPastDiff;
    for (int i = 0; i < events.length; i++) {
      final e = events[i];
      final diff = (now.difference(e.endDate)).abs();
      if (minPastDiff == null || diff < minPastDiff) {
        minPastDiff = diff;
        pastIdx = i;
      }
    }
    if (pastIdx != null) return pastIdx;

    return 0;
  }

  /// Returns the default landing EventEntity, or null if list is empty.
  static EventEntity? findDefaultEvent(List<EventEntity> events,
      [DateTime? clock]) {
    if (events.isEmpty) return null;
    final idx = findDefaultEventIndex(events, clock);
    if (idx >= 0 && idx < events.length) return events[idx];
    return events.first;
  }

  EventEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? venue,
    String? banner,
    bool? isAttendanceOpen,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? capacity,
    String? status,
  }) {
    return EventEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      venue: venue ?? this.venue,
      banner: banner ?? this.banner,
      isAttendanceOpen: isAttendanceOpen ?? this.isAttendanceOpen,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
    );
  }
}
