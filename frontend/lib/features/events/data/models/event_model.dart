import '../../domain/entities/event_entity.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String type;
  final int capacity;
  final String status;

  const EventModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.capacity,
    required this.status,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
        id: json['_id'] as String? ?? json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        startDate: json['startDate'] != null
            ? DateTime.parse(json['startDate'] as String)
            : DateTime.now(),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : DateTime.now(),
        type: json['type'] as String? ?? 'general',
        capacity: json['capacity'] as int? ?? 0,
        status: json['status'] as String? ?? 'upcoming',
      );

  EventEntity toEntity() => EventEntity(
        id: id,
        title: title,
        startDate: startDate,
        endDate: endDate,
        type: type,
        capacity: capacity,
        status: status,
      );
}
