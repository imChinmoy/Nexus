import '../../domain/entities/event_entity.dart';

class EventModel {
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

  const EventModel({
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

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        venue: json['venue'] as String?,
        banner: json['banner'] as String?,
        isAttendanceOpen: json['isAttendanceOpen'] as bool? ?? false,
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String).toLocal()
            : DateTime.now(),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String).toLocal()
            : DateTime.now(),
        type: json['type'] as String? ?? 'general',
        capacity: json['capacity'] as int? ?? 0,
        status: json['status'] as String? ?? 'upcoming',
      );

  EventEntity toEntity() => EventEntity(
        id: id,
        title: title,
        description: description,
        venue: venue,
        banner: banner,
        isAttendanceOpen: isAttendanceOpen,
        startDate: startDate,
        endDate: endDate,
        type: type,
        capacity: capacity,
        status: status,
      );
}
