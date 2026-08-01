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
}
