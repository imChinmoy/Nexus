class EventEntity {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final int capacity;
  final String status;

  const EventEntity({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.capacity,
    required this.status,
  });
}
