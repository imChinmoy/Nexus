import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/event_model.dart';

abstract interface class EventRemoteSource {
  Future<List<EventModel>> getEvents();
  Future<EventModel> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
  });
}

class EventRemoteSourceImpl implements EventRemoteSource {
  final Dio _dio;

  EventRemoteSourceImpl(this._dio);

  @override
  Future<List<EventModel>> getEvents() async {
    try {
      final response = await _dio.get(ApiConstants.events);
      if (response.data['data'] == null) return [];
      return (response.data['data'] as List)
          .map((json) => EventModel.fromJson(json))
          .toList();
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to fetch events: ${e.toString()}');
    }
  }

  @override
  Future<EventModel> createEvent({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    required int capacity,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.events,
        data: {
          'title': title,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'type': type,
          'capacity': capacity,
        },
      );
      return EventModel.fromJson(response.data['data']);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to create event: ${e.toString()}');
    }
  }
}
